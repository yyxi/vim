local M = {}

-- Privileged editing in this repository is intentionally narrow.
--
-- Contract:
-- - only preauthorized, non-interactive sudo is supported;
-- - authentication happens outside Neovim via the normal terminal/PAM flow;
-- - only existing regular-file targets are supported for privileged I/O, including symlink paths whose
--   resolved target is an existing regular file;
-- - supported writes are same-underlying-path whole-buffer writes only;
-- - supported buffers are text buffers with 'binary' off and 'fileencoding' unset or 'utf-8';
-- - privileged file creation, :saveas, :write {other-path}, ranged writes, broken symlinks, and
--   non-regular targets are rejected.
--
-- Design choices that are easy to miss:
-- - exact privileged operations run first; 'sudo -n true' is only a secondary classifier after failure;
-- - existing files are written directly with 'tee' so the opened path and the resolved target inode stay in
--   place;
-- - no temporary privileged content files are used in the normal path;
-- - swapfile and persistent undo are disabled for candidate and managed privileged buffers;
-- - write-capable privileged buffers use a synthetic 'sudo://' name so :w and :wall reach BufWriteCmd instead
--   of Neovim's normal read-only-on-disk preflight;
-- - blocked reads keep the real path, stay readonly/non-modifiable, and require :edit! or reopen after
--   external preauthorization;
-- - read recovery is a best-effort post-open repair with BufRead/BufReadPost replay, not a full BufReadCmd
--   replacement;
-- - path classification is best-effort and not atomic against later path replacement.
local utf8_validator = require('yyxi.utilities.utf8_validator')

local uv = vim.uv or vim.loop

local GROUP_NAME = 'PrivilegedEditing'
local MANAGED_NAME_PREFIX = 'sudo://'
local DEFAULT_LOG_LEVEL = vim.log.levels.WARN

local config = {
  log_level = DEFAULT_LOG_LEVEL,
}

local STATE_IGNORE = 'ignore'
local STATE_PLAIN = 'plain'
local STATE_CANDIDATE_READ = 'candidate-read'
local STATE_CANDIDATE_WRITE = 'candidate-write'
local STATE_MANAGED = 'managed'
local STATE_BLOCKED_READ = 'blocked-read'
local STATE_UNSUPPORTED_CREATE = 'unsupported-create'
local STATE_UNSUPPORTED_FILETYPE = 'unsupported-filetype'
local STATE_UNSUPPORTED_BUFFER_MODE = 'unsupported-buffer-mode'
local STATE_SETUP_FAILED = 'setup-failed'

local BV_STATE = 'privileged_editing_state'
local BV_PATH = 'privileged_editing_path'
local BV_REASON = 'privileged_editing_reason'

local buffers = {}
local augroup_id = nil

---@class yyxi.privileged_editing.Preclassification
---@field kind string
---@field path string
---@field exists boolean
---@field readable boolean
---@field writable boolean
---@field parent? string
---@field filetype? string

local function ensure_buffer_state(bufnr)
  local state = buffers[bufnr]
  if state then return state end

  state = {
    kind = nil,
    path = nil,
    reason = nil,
    saved_swapfile = nil,
    saved_undofile = nil,
    hardening_saved = false,
    renaming = false,
    announcements = {},
    autocmd_ids = {},
  }
  buffers[bufnr] = state
  return state
end

local function set_buffer_var(bufnr, key, value)
  pcall(function() vim.b[bufnr][key] = value end)
end

local function set_state(bufnr, kind)
  ensure_buffer_state(bufnr).kind = kind
  set_buffer_var(bufnr, BV_STATE, kind)
end

local function set_reason(bufnr, reason)
  ensure_buffer_state(bufnr).reason = reason
  set_buffer_var(bufnr, BV_REASON, reason)
end

local function set_managed_path(bufnr, path)
  ensure_buffer_state(bufnr).path = path
  set_buffer_var(bufnr, BV_PATH, path)
end

local function clear_announcements(bufnr) ensure_buffer_state(bufnr).announcements = {} end

local attach_buffer_handlers
local nearest_existing_parent
local same_path_identity
local run_sudo
local run_sudo_true

local function detach_buffer_autocmds(bufnr)
  local state = buffers[bufnr]
  if not state then return end

  for _, autocmd_id in ipairs(state.autocmd_ids) do
    pcall(vim.api.nvim_del_autocmd, autocmd_id)
  end
  state.autocmd_ids = {}
end

local function reset_runtime_state(bufnr)
  detach_buffer_autocmds(bufnr)
  buffers[bufnr] = nil

  set_buffer_var(bufnr, BV_STATE, nil)
  set_buffer_var(bufnr, BV_PATH, nil)
  set_buffer_var(bufnr, BV_REASON, nil)
end

local function is_managed_buffer_name(name) return vim.startswith(name or '', MANAGED_NAME_PREFIX) end

local function is_uri_path(path)
  if path == '' or is_managed_buffer_name(path) then return false end
  return path:match('^[A-Za-z][A-Za-z0-9+.-]*://') ~= nil
end

local function normalize_path(path)
  if path == nil or path == '' then return '' end
  return vim.fs.normalize(vim.fn.fnamemodify(path, ':p'))
end

local function resolve_path(path)
  if path == nil or path == '' then return '' end
  if is_managed_buffer_name(path) then return normalize_path(path:sub(#MANAGED_NAME_PREFIX + 1)) end
  return normalize_path(path)
end

local function raw_name_of(bufnr) return vim.api.nvim_buf_get_name(bufnr) end

local function managed_buffer_name(path) return MANAGED_NAME_PREFIX .. normalize_path(path) end

local function path_of(bufnr) return resolve_path(raw_name_of(bufnr)) end

local function ensure_managed_buffer_name(bufnr, path)
  local name = managed_buffer_name(path)
  if raw_name_of(bufnr) == name then return true end

  local state = ensure_buffer_state(bufnr)
  state.renaming = true
  local ok, error_message = pcall(vim.api.nvim_buf_set_name, bufnr, name)
  state.renaming = false

  if ok then return true end
  return false, tostring(error_message)
end

local function ensure_real_buffer_name(bufnr, path)
  local name = normalize_path(path)
  local raw_name = raw_name_of(bufnr)
  if raw_name == name then return true end
  if not is_managed_buffer_name(raw_name) and same_path_identity(raw_name, name) then
    return true
  end

  local state = ensure_buffer_state(bufnr)
  state.renaming = true
  local ok, error_message = pcall(vim.api.nvim_buf_set_name, bufnr, name)
  state.renaming = false

  if ok then return true end
  return false, tostring(error_message)
end

local function extract_errno_name(error_message, errname)
  if errname and errname ~= '' then return errname end
  if type(error_message) ~= 'string' then return nil end
  return error_message:match('^([A-Z0-9_]+):')
end

local function lstat_path(path)
  if path == '' then return nil, nil end

  local entry, error_message, errname = uv.fs_lstat(path)
  return entry, extract_errno_name(error_message, errname)
end

local function stat_path(path)
  if path == '' then return nil, nil end

  local entry, error_message, errname = uv.fs_stat(path)
  return entry, extract_errno_name(error_message, errname)
end

local function realpath_path(path)
  if path == '' then return nil, nil end

  local resolved_path, error_message, errname = uv.fs_realpath(path)
  if not resolved_path then return nil, extract_errno_name(error_message, errname) end
  return normalize_path(resolved_path), nil
end

-- Normalize aliasing through existing ancestors so `/var/...` and `/private/var/...`
-- compare equal without replacing the user-facing path that the feature preserves.
local function canonical_path_identity(path)
  path = normalize_path(path)
  if path == '' then return '' end

  local resolved_path = realpath_path(path)
  if resolved_path then return resolved_path end

  local parent = nearest_existing_parent(path)
  if not parent then return path end

  local resolved_parent = realpath_path(parent)
  if not resolved_parent then return path end

  return resolved_parent .. path:sub(#parent + 1)
end

local function normalize_identity_path(path)
  if is_managed_buffer_name(path) then return resolve_path(path) end
  return normalize_path(path)
end

same_path_identity = function(lhs, rhs)
  lhs = normalize_identity_path(lhs)
  rhs = normalize_identity_path(rhs)
  if lhs == rhs then return true end
  return canonical_path_identity(lhs) == canonical_path_identity(rhs)
end

local function is_file_buffer(bufnr)
  if vim.bo[bufnr].buftype ~= '' then return false end

  local name = raw_name_of(bufnr)
  if name == '' or is_uri_path(name) then return false end

  local path = path_of(bufnr)
  local entry = stat_path(path)
  if entry and entry.type == 'directory' then return false end

  return true
end

nearest_existing_parent = function(path)
  local current = normalize_path(path)
  if current == '' then return nil end

  current = vim.fs.dirname(current)
  while current and current ~= '' do
    local entry = lstat_path(current)
    if entry then return current end

    local parent = vim.fs.dirname(current)
    if not parent or parent == current then break end
    current = parent
  end

  return nil
end

local function is_unsupported_special_path(path)
  return path == '/proc'
    or path:sub(1, 6) == '/proc/'
    or path == '/sys'
    or path:sub(1, 5) == '/sys/'
    or path == '/dev/fd'
    or path:sub(1, 8) == '/dev/fd/'
    or path == '/dev/stdin'
    or path == '/dev/stdout'
    or path == '/dev/stderr'
end

local function is_missing_path_errno(errname) return errname == 'ENOENT' or errname == 'ENOTDIR' end

local function is_permission_denied_errno(errname) return errname == 'EACCES' or errname == 'EPERM' end

local function preclassification(kind, path, exists, readable, writable, extra)
  local result = {
    kind = kind,
    path = path,
    exists = exists,
    readable = readable,
    writable = writable,
  }

  if extra then
    for key, value in pairs(extra) do
      result[key] = value
    end
  end

  return result
end

local function permission_denied_existing_regular_file(path, filetype)
  return preclassification(STATE_CANDIDATE_READ, path, true, false, false, {
    filetype = filetype,
  })
end

local function is_effectively_unsupported_special_path(path)
  if is_unsupported_special_path(path) then return true end

  local resolved_path = realpath_path(path)
  return resolved_path ~= nil and is_unsupported_special_path(resolved_path)
end

local function sudo_probe_test(path, predicate)
  local result = run_sudo({ 'test', predicate, path }, {
    stdout = false,
    stderr = false,
  })

  if result.code == 0 then return true end
  if result.code == 1 then return false end
  return nil
end

-- A permission-denied stat can mean either "existing path behind an unreadable
-- directory" or "missing path under an unreadable directory". Probe the effective
-- target type with portable `test` predicates that follow symlinks for `-f` and
-- `-d`, while `-L` still preserves existing broken-symlink detection. If all tests
-- report false, one final `sudo -n true` distinguishes a genuinely missing path
-- from an unauthorized probe.
local function sudo_probe_path_filetype(path)
  local is_file = sudo_probe_test(path, '-f')
  if is_file == true then return 'file', true end
  if is_file == nil then return nil, nil end

  local is_directory = sudo_probe_test(path, '-d')
  if is_directory == true then return 'directory', true end
  if is_directory == nil then return nil, nil end

  local is_link = sudo_probe_test(path, '-L')
  if is_link == true then return 'link', true end
  if is_link == nil then return nil, nil end

  local exists = sudo_probe_test(path, '-e')
  if exists == true then return 'other', true end
  if exists == nil then return nil, nil end

  local classifier = run_sudo_true()
  if classifier.code == 0 then return nil, false end
  return nil, nil
end

local function classify_existing_path(path, filetype, readable, writable)
  if filetype == 'directory' then
    return preclassification(STATE_IGNORE, path, true, false, false, { filetype = filetype })
  end

  if is_effectively_unsupported_special_path(path) or filetype ~= 'file' then
    return preclassification(STATE_UNSUPPORTED_FILETYPE, path, true, readable, writable, {
      filetype = filetype,
    })
  end

  if readable and writable then
    return preclassification(STATE_PLAIN, path, true, readable, writable, {
      filetype = filetype,
    })
  end

  if not readable then
    return preclassification(STATE_CANDIDATE_READ, path, true, readable, writable, {
      filetype = filetype,
    })
  end

  return preclassification(STATE_CANDIDATE_WRITE, path, true, readable, writable, {
    filetype = filetype,
  })
end

local function classify_permission_denied_path(path)
  local filetype, exists = sudo_probe_path_filetype(path)
  if exists == false then
    return preclassification(STATE_UNSUPPORTED_CREATE, path, false, false, false)
  end

  if filetype == 'directory' then
    return preclassification(STATE_IGNORE, path, true, false, false, { filetype = filetype })
  end

  if filetype then
    if is_effectively_unsupported_special_path(path) or filetype ~= 'file' then
      return preclassification(
        STATE_UNSUPPORTED_FILETYPE,
        path,
        true,
        false,
        false,
        { filetype = filetype }
      )
    end

    return permission_denied_existing_regular_file(path, filetype)
  end

  return permission_denied_existing_regular_file(path)
end

local function is_supported_fileencoding(bufnr)
  local fileencoding = vim.bo[bufnr].fileencoding
  return fileencoding == '' or fileencoding == 'utf-8'
end

local function is_supported_buffer_mode(bufnr)
  if vim.bo[bufnr].binary then return false end
  return is_supported_fileencoding(bufnr)
end

local function supported_mode_message()
  return 'Privileged editing is limited to UTF-8 text buffers with binary mode off.'
end

local function needs_sensitive_hardening(kind)
  return kind == STATE_CANDIDATE_READ or kind == STATE_CANDIDATE_WRITE
end

---@param path string
---@return yyxi.privileged_editing.Preclassification
local function preclassify_path(path)
  path = normalize_path(path)
  if path == '' or is_uri_path(path) then
    return preclassification(STATE_IGNORE, path, false, false, false)
  end

  local lstat_entry, lstat_error = lstat_path(path)
  if lstat_entry then
    local effective_entry = lstat_entry

    if lstat_entry.type == 'link' then
      local resolved_entry, effective_error = stat_path(path)
      if not resolved_entry then
        if is_permission_denied_errno(effective_error) then
          return classify_permission_denied_path(path)
        end
        return preclassification(STATE_UNSUPPORTED_FILETYPE, path, true, false, false, {
          filetype = lstat_entry.type,
        })
      end
      effective_entry = resolved_entry
    end

    local readable = vim.fn.filereadable(path) == 1
    local writable = vim.fn.filewritable(path) == 1
    return classify_existing_path(path, effective_entry.type, readable, writable)
  end

  if is_permission_denied_errno(lstat_error) then return classify_permission_denied_path(path) end

  local parent = nearest_existing_parent(path)
  if is_missing_path_errno(lstat_error) and parent and vim.fn.filewritable(parent) == 2 then
    return preclassification(STATE_PLAIN, path, false, false, true, { parent = parent })
  end

  return preclassification(STATE_UNSUPPORTED_CREATE, path, false, false, false, { parent = parent })
end

local function is_valid_log_level(level)
  return type(level) == 'number' and level >= vim.log.levels.TRACE and level <= vim.log.levels.OFF
end

local function configure_logging(opts)
  opts = opts or {}
  if type(opts) ~= 'table' then
    error('privileged_editing.configure: opts must be a table or nil')
  end

  local log_level = opts.log_level
  if log_level == nil then
    config.log_level = DEFAULT_LOG_LEVEL
    return
  end

  if not is_valid_log_level(log_level) then
    error(
      string.format(
        'privileged_editing.configure: opts.log_level must be one of vim.log.levels.* (got %s)',
        vim.inspect(log_level)
      )
    )
  end

  config.log_level = log_level
end

local function should_log(level)
  level = level or vim.log.levels.INFO
  return level >= config.log_level
end

local function notify(message, level)
  level = level or vim.log.levels.INFO
  if not should_log(level) then return false end

  vim.notify(message, level)
  return true
end

local function emit_once(bufnr, key, message, level)
  local state = ensure_buffer_state(bufnr)
  if state.announcements[key] then return false end
  if not notify(message, level) then return false end

  state.announcements[key] = true
  return true
end

local function harden_sensitive_buffer(bufnr)
  local state = ensure_buffer_state(bufnr)
  if not state.hardening_saved then
    state.saved_swapfile = vim.bo[bufnr].swapfile
    state.saved_undofile = vim.bo[bufnr].undofile
    state.hardening_saved = true
  end

  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].undofile = false
end

local function restore_non_sensitive_buffer_options(bufnr)
  local state = ensure_buffer_state(bufnr)
  if not state.hardening_saved then return end

  vim.bo[bufnr].swapfile = state.saved_swapfile
  vim.bo[bufnr].undofile = state.saved_undofile
  state.saved_swapfile = nil
  state.saved_undofile = nil
  state.hardening_saved = false
end

local function parse_text_bytes(raw, fallback_fileformat)
  fallback_fileformat = fallback_fileformat or 'unix'
  if raw:find('\0', 1, true) then return nil, 'Privileged editing does not support NUL bytes.' end

  local valid_utf8, invalid_byte = utf8_validator.validate(raw)
  if not valid_utf8 then
    return nil,
      string.format(
        'Privileged editing does not support invalid UTF-8 data (first invalid byte at %d).',
        invalid_byte
      )
  end

  if raw == '' then
    return {
      lines = { '' },
      fileformat = fallback_fileformat,
      endofline = true,
    }
  end

  local lines = {}
  local first_separator = nil
  local start = 1
  local index = 1
  local length = #raw

  while index <= length do
    local byte = raw:byte(index)
    if byte == 13 then
      local separator = 'mac'
      local separator_end = index
      if raw:byte(index + 1) == 10 then
        separator = 'dos'
        separator_end = index + 1
      end

      first_separator = first_separator or separator
      table.insert(lines, raw:sub(start, index - 1))
      start = separator_end + 1
      index = separator_end + 1
    elseif byte == 10 then
      first_separator = first_separator or 'unix'
      table.insert(lines, raw:sub(start, index - 1))
      start = index + 1
      index = index + 1
    else
      index = index + 1
    end
  end

  local endofline = start > length
  if not endofline and start <= length then table.insert(lines, raw:sub(start)) end

  if #lines == 0 then lines = { '' } end

  return {
    lines = lines,
    fileformat = first_separator or fallback_fileformat,
    endofline = endofline,
  }
end

local function serialize_buffer(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local separator = ({ dos = '\r\n', unix = '\n', mac = '\r' })[vim.bo[bufnr].fileformat] or '\n'
  local final_eol = vim.bo[bufnr].fixendofline and not vim.bo[bufnr].binary
    or vim.bo[bufnr].endofline
  local text = table.concat(lines, separator)
  if final_eol then text = text .. separator end
  return text
end

local function summarize_stderr(stderr)
  stderr = stderr or ''
  for line in stderr:gmatch('[^\r\n]+') do
    local trimmed = vim.trim(line)
    if trimmed ~= '' then return trimmed end
  end
  return ''
end

local function transition_buffer(bufnr, target)
  local path = target.path or ensure_buffer_state(bufnr).path or path_of(bufnr)

  -- Detach buffer-local handlers before any internal rename back to the real path.
  -- Otherwise BufFilePre rejection for managed buffers can trip on the feature's own
  -- downgrade/setup transitions.
  if target.attach_handlers == false then detach_buffer_autocmds(bufnr) end

  if target.name_mode == 'managed' then
    local ok, error_message = ensure_managed_buffer_name(bufnr, path)
    if not ok then return false, error_message end
  elseif target.name_mode == 'real' then
    local ok, error_message = ensure_real_buffer_name(bufnr, path)
    if not ok then return false, error_message end
  end

  if target.sensitive == true then
    harden_sensitive_buffer(bufnr)
  elseif target.sensitive == false then
    restore_non_sensitive_buffer_options(bufnr)
  end

  if target.attach_handlers == true then attach_buffer_handlers(bufnr) end

  set_managed_path(bufnr, path)
  set_state(bufnr, target.kind)
  set_reason(bufnr, target.reason)

  if target.modifiable ~= nil then vim.bo[bufnr].modifiable = target.modifiable end
  if target.readonly ~= nil then vim.bo[bufnr].readonly = target.readonly end

  return true
end

local function setup_failed_message(path, detail)
  return string.format(
    'Privileged editing setup failed for %s: could not complete the managed buffer transition: %s',
    path,
    detail
  )
end

local function enter_setup_failed(bufnr, path, detail)
  local reason = setup_failed_message(path, detail)
  local ok = transition_buffer(bufnr, {
    kind = STATE_SETUP_FAILED,
    path = path,
    reason = reason,
    name_mode = 'managed',
    sensitive = true,
    attach_handlers = true,
    modifiable = true,
    readonly = false,
  })

  if not ok then
    transition_buffer(bufnr, {
      kind = STATE_SETUP_FAILED,
      path = path,
      reason = reason,
      sensitive = true,
      attach_handlers = true,
      modifiable = true,
      readonly = false,
    })
  end

  emit_once(bufnr, STATE_SETUP_FAILED, reason, vim.log.levels.WARN)
  return false, reason
end

-- Failed privileged reads stay terminal until an explicit reread. Keeping the real
-- path and making the buffer readonly/non-modifiable avoids accidentally editing an
-- empty stand-in for contents that were never loaded.
local function set_blocked_read_state(bufnr, path, reason)
  local ok, error_message = transition_buffer(bufnr, {
    kind = STATE_BLOCKED_READ,
    path = path,
    reason = reason,
    name_mode = 'real',
    sensitive = true,
    attach_handlers = true,
    modifiable = false,
    readonly = true,
  })
  if ok then return true end
  return enter_setup_failed(bufnr, path, error_message)
end

local function transition_write_capable_state(bufnr, kind, path)
  return transition_buffer(bufnr, {
    kind = kind,
    path = path,
    reason = nil,
    name_mode = 'managed',
    sensitive = true,
    attach_handlers = true,
    modifiable = true,
    readonly = false,
  })
end

local function success_message(action, path)
  return string.format('%s succeeded for %s.', action, path)
end

local function auth_retry_hint(action)
  if action == 'Privileged read' then return ". Preauthorize with 'sudo -v' and reopen." end
  return ". Preauthorize with 'sudo -v' and try again."
end

local function sudo_invocation_failed_message(action, path, detail)
  if detail ~= '' then
    return string.format('%s failed for %s: unable to invoke sudo: %s', action, path, detail)
  end
  return string.format('%s failed for %s: unable to invoke sudo.', action, path)
end

local function op_failed_message(action, path, detail)
  if detail ~= '' then return string.format('%s failed for %s: %s', action, path, detail) end
  return string.format('%s failed for %s.', action, path)
end

local function unsupported_create_message(path)
  return string.format(
    'Privileged create is unsupported for %s. Create the file outside Neovim with the desired owner and mode, then reopen it.',
    path
  )
end

local function unsupported_filetype_message(path)
  return string.format('Privileged editing is unsupported for non-regular path %s.', path)
end

local function unsupported_alternate_path_message(path, requested)
  return string.format(
    'Privileged alternate-path write is unsupported for %s (requested %s).',
    path,
    requested
  )
end

local function unsupported_ranged_write_message(path)
  return string.format('Privileged ranged or partial writes are unsupported for %s.', path)
end

local function unsupported_saveas_message(path)
  return string.format('Privileged path mutation is unsupported for managed buffer %s.', path)
end

local function unsupported_state_message(bufnr)
  local state = ensure_buffer_state(bufnr)
  if state.reason and state.reason ~= '' then return state.reason end

  if state.kind == STATE_UNSUPPORTED_CREATE then
    return unsupported_create_message(state.path or path_of(bufnr))
  end
  if state.kind == STATE_UNSUPPORTED_FILETYPE then
    return unsupported_filetype_message(state.path or path_of(bufnr))
  end
  if state.kind == STATE_UNSUPPORTED_BUFFER_MODE then return supported_mode_message() end
  if state.kind == STATE_BLOCKED_READ then return 'Privileged read is blocked for this buffer.' end
  return 'Privileged write is unsupported for this buffer.'
end

local function default_run_sudo(argv, opts)
  opts = opts or {}
  local command = { 'sudo', '-n', '--' }
  vim.list_extend(command, argv)

  local ok, system_obj = pcall(vim.system, command, {
    stdin = opts.stdin,
    stdout = opts.stdout == nil and true or opts.stdout,
    stderr = opts.stderr == nil and true or opts.stderr,
    text = false,
  })

  if not ok then
    return {
      code = -1,
      signal = 0,
      stdout = '',
      stderr = tostring(system_obj),
    }
  end

  local result = system_obj:wait()
  return {
    code = result.code,
    signal = result.signal,
    stdout = result.stdout or '',
    stderr = result.stderr or '',
  }
end

local run_sudo_impl = default_run_sudo

run_sudo = function(argv, opts) return run_sudo_impl(argv, opts or {}) end

run_sudo_true = function() return run_sudo({ 'true' }, { stdout = false }) end

local function classify_failed_operation(action, path, exact_result)
  local detail = summarize_stderr(exact_result.stderr)
  if exact_result.code == -1 then
    return false, sudo_invocation_failed_message(action, path, detail)
  end

  local message = op_failed_message(action, path, detail)
  local classifier = run_sudo_true()
  if classifier.code == 0 or classifier.code == -1 then return false, message end
  return false, message .. auth_retry_hint(action)
end

local function apply_parsed_text(bufnr, parsed)
  vim.bo[bufnr].fileformat = parsed.fileformat
  vim.bo[bufnr].endofline = parsed.endofline
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, parsed.lines)
end

local function attach_buffer_autocmd(bufnr, event, callback)
  local state = ensure_buffer_state(bufnr)
  local autocmd_id = vim.api.nvim_create_autocmd(event, {
    group = augroup_id,
    buffer = bufnr,
    callback = callback,
  })
  table.insert(state.autocmd_ids, autocmd_id)
end

-- Privileged reads happen after Neovim's native open path has already failed, so the
-- feature replays a narrow subset of normal read lifecycle hooks after loading the real
-- content. This is intentionally best-effort rather than a full native-read emulation.
local function replay_read_autocmds(bufnr, path)
  vim.api.nvim_buf_call(bufnr, function()
    local escaped_path = vim.fn.fnameescape(path)
    vim.cmd('silent doautocmd <nomodeline> BufRead ' .. escaped_path)
    vim.cmd('silent doautocmd <nomodeline> BufReadPost ' .. escaped_path)
  end)
end

local function read_privileged_into_buffer(bufnr, path)
  local result = run_sudo({ 'cat', path })
  if result.code ~= 0 then return classify_failed_operation('Privileged read', path, result) end

  local parsed, parse_error = parse_text_bytes(result.stdout, vim.bo[bufnr].fileformat)
  if not parsed then return false, parse_error end

  vim.bo[bufnr].modifiable = true
  vim.bo[bufnr].readonly = false
  apply_parsed_text(bufnr, parsed)
  vim.bo[bufnr].modified = false
  return true, success_message('Privileged read', path)
end

-- Write directly into the existing path. This avoids copy-over or rename-over
-- semantics that could replace the inode and lose owner/mode/ACL/xattr/label state.
local function write_privileged_buffer(bufnr, path)
  local pre = preclassify_path(path)
  if not pre.exists then return false, unsupported_create_message(path) end
  if pre.kind == STATE_UNSUPPORTED_FILETYPE then
    return false, unsupported_filetype_message(path)
  end
  if not is_supported_buffer_mode(bufnr) then return false, supported_mode_message() end

  local text = serialize_buffer(bufnr)
  -- 'tee' gives a direct stdin-to-path write without a shell or temporary file.
  local result = run_sudo({ 'tee', path }, {
    stdin = text,
    stdout = false,
  })
  if result.code ~= 0 then return classify_failed_operation('Privileged write', path, result) end

  vim.bo[bufnr].modified = false
  return true, success_message('Privileged write', path)
end

local function reject_with_error(message)
  vim.api.nvim_err_writeln(message)
  return false, message
end

local function handle_buf_write_request(bufnr, requested_path)
  local state = ensure_buffer_state(bufnr)
  local canonical_path = state.path or path_of(bufnr)
  local normalized_requested_path = resolve_path(requested_path)
  if normalized_requested_path == '' then normalized_requested_path = canonical_path end

  if not same_path_identity(normalized_requested_path, canonical_path) then
    return reject_with_error(
      unsupported_alternate_path_message(canonical_path, normalized_requested_path)
    )
  end

  if not is_supported_buffer_mode(bufnr) then return reject_with_error(supported_mode_message()) end

  if state.kind == STATE_MANAGED or state.kind == STATE_CANDIDATE_WRITE then
    local ok, message = write_privileged_buffer(bufnr, canonical_path)
    if not ok then return reject_with_error(message) end
    return true, message
  end

  return reject_with_error(unsupported_state_message(bufnr))
end

local function handle_file_write_request(bufnr)
  local path = ensure_buffer_state(bufnr).path or path_of(bufnr)
  return reject_with_error(unsupported_ranged_write_message(path))
end

local function handle_file_append_request(bufnr)
  local path = ensure_buffer_state(bufnr).path or path_of(bufnr)
  return reject_with_error(unsupported_ranged_write_message(path))
end

local function handle_buf_file_pre(bufnr)
  local path = ensure_buffer_state(bufnr).path or path_of(bufnr)
  return reject_with_error(unsupported_saveas_message(path))
end

attach_buffer_handlers = function(bufnr)
  local state = ensure_buffer_state(bufnr)
  if #state.autocmd_ids > 0 then return end

  attach_buffer_autocmd(bufnr, 'BufWriteCmd', function(args)
    local ok, message = handle_buf_write_request(args.buf, args.match or raw_name_of(args.buf))
    if ok and should_log(vim.log.levels.INFO) then vim.api.nvim_echo({ { message } }, true, {}) end
  end)
  attach_buffer_autocmd(
    bufnr,
    'FileWriteCmd',
    function(args) handle_file_write_request(args.buf) end
  )
  attach_buffer_autocmd(
    bufnr,
    'FileAppendCmd',
    function(args) handle_file_append_request(args.buf) end
  )
  attach_buffer_autocmd(bufnr, 'BufFilePre', function(args) handle_buf_file_pre(args.buf) end)
end

local function is_content_loaded_state(kind)
  return kind == STATE_CANDIDATE_WRITE
    or kind == STATE_MANAGED
    or kind == STATE_UNSUPPORTED_BUFFER_MODE
    or kind == STATE_SETUP_FAILED
end

local function is_terminal_without_reread(kind)
  return kind == STATE_BLOCKED_READ or kind == STATE_SETUP_FAILED
end

-- Privileged-related unsupported states still use managed names and rejection handlers
-- when possible. That keeps later :w/:wall under module control instead of falling
-- through to unrelated native errors for a protected path.
local function finalize_unsupported_candidate(bufnr, kind, path, reason)
  local ok, error_message = transition_buffer(bufnr, {
    kind = kind,
    path = path,
    reason = reason,
    name_mode = 'managed',
    sensitive = true,
    attach_handlers = true,
    modifiable = true,
    readonly = false,
  })
  if not ok then return enter_setup_failed(bufnr, path, error_message) end

  emit_once(bufnr, kind, reason, vim.log.levels.WARN)
  return true
end

local function finalize_supported_candidate_write(bufnr, path)
  local ok, error_message = transition_write_capable_state(bufnr, STATE_CANDIDATE_WRITE, path)
  if not ok then return enter_setup_failed(bufnr, path, error_message) end

  emit_once(
    bufnr,
    'candidate-write',
    string.format('Privileged write enabled for %s: using non-interactive sudo on save.', path),
    vim.log.levels.INFO
  )
  return true
end

local function finalize_candidate_read(bufnr, path)
  set_managed_path(bufnr, path)
  emit_once(
    bufnr,
    'candidate-read-start',
    string.format('Privileged read for %s: trying non-interactive sudo.', path),
    vim.log.levels.INFO
  )

  local ok, message = read_privileged_into_buffer(bufnr, path)
  if not ok then
    set_blocked_read_state(bufnr, path, message)
    notify(message, vim.log.levels.ERROR)
    return
  end

  replay_read_autocmds(bufnr, path)
  if not is_supported_buffer_mode(bufnr) then
    finalize_unsupported_candidate(
      bufnr,
      STATE_UNSUPPORTED_BUFFER_MODE,
      path,
      supported_mode_message()
    )
    return
  end

  local transitioned, error_message = transition_write_capable_state(bufnr, STATE_MANAGED, path)
  if not transitioned then
    enter_setup_failed(bufnr, path, error_message)
    return
  end

  notify(message, vim.log.levels.INFO)
end

local function clear_feature_for_plain_buffer(bufnr)
  local path = path_of(bufnr)
  local downgraded = is_content_loaded_state(ensure_buffer_state(bufnr).kind)
  local ok, error_message = transition_buffer(bufnr, {
    kind = STATE_PLAIN,
    path = path,
    reason = nil,
    name_mode = 'real',
    sensitive = false,
    attach_handlers = false,
  })
  if not ok then return enter_setup_failed(bufnr, path, error_message) end

  if downgraded then
    emit_once(
      bufnr,
      'downgraded-plain',
      string.format('Privileged handling disabled for %s: file no longer requires sudo.', path),
      vim.log.levels.INFO
    )
  end

  return true
end

local function pre_read_prepare(bufnr, path)
  if path == '' then return end

  local state = ensure_buffer_state(bufnr)
  if state.path ~= path then clear_announcements(bufnr) end
  set_managed_path(bufnr, path)

  local pre = preclassify_path(path)
  if needs_sensitive_hardening(pre.kind) then harden_sensitive_buffer(bufnr) end

  if pre.kind == STATE_CANDIDATE_READ or pre.kind == STATE_CANDIDATE_WRITE then
    set_state(bufnr, pre.kind)
    set_reason(bufnr, nil)
  elseif pre.kind == STATE_UNSUPPORTED_CREATE then
    set_state(bufnr, STATE_UNSUPPORTED_CREATE)
    set_reason(bufnr, unsupported_create_message(path))
  elseif pre.kind == STATE_UNSUPPORTED_FILETYPE then
    set_state(bufnr, STATE_UNSUPPORTED_FILETYPE)
    set_reason(bufnr, unsupported_filetype_message(path))
  end
end

local function finalize_buffer(bufnr)
  if not is_file_buffer(bufnr) then return end

  local state = ensure_buffer_state(bufnr)
  if is_terminal_without_reread(state.kind) then return end

  local current_path = path_of(bufnr)
  if current_path == '' then return end

  local path = current_path
  local stored_path = state.path
  if
    state.kind ~= nil
    and state.kind ~= STATE_PLAIN
    and type(stored_path) == 'string'
    and stored_path ~= ''
  then
    if same_path_identity(stored_path, current_path) then path = stored_path end
  end

  local pre = preclassify_path(path)
  if pre.kind == STATE_PLAIN then
    clear_feature_for_plain_buffer(bufnr)
    return
  end

  if pre.kind == STATE_UNSUPPORTED_CREATE then
    finalize_unsupported_candidate(bufnr, pre.kind, path, unsupported_create_message(path))
    return
  end

  if pre.kind == STATE_UNSUPPORTED_FILETYPE then
    finalize_unsupported_candidate(bufnr, pre.kind, path, unsupported_filetype_message(path))
    return
  end

  if not is_supported_buffer_mode(bufnr) then
    finalize_unsupported_candidate(
      bufnr,
      STATE_UNSUPPORTED_BUFFER_MODE,
      path,
      supported_mode_message()
    )
    return
  end

  if pre.kind == STATE_CANDIDATE_READ then
    if is_content_loaded_state(state.kind) then
      if state.kind == STATE_MANAGED then return end

      local transitioned, error_message = transition_write_capable_state(bufnr, STATE_MANAGED, path)
      if not transitioned then enter_setup_failed(bufnr, path, error_message) end
      return
    end

    finalize_candidate_read(bufnr, path)
    return
  end

  if pre.kind == STATE_CANDIDATE_WRITE then finalize_supported_candidate_write(bufnr, path) end
end

function M.configure(opts)
  configure_logging(opts)

  if augroup_id ~= nil then pcall(vim.api.nvim_del_augroup_by_id, augroup_id) end
  augroup_id = vim.api.nvim_create_augroup(GROUP_NAME, { clear = true })

  vim.api.nvim_create_autocmd('BufReadPre', {
    group = augroup_id,
    pattern = '*',
    callback = function(args)
      local path = normalize_path(args.match or vim.api.nvim_buf_get_name(args.buf))
      pre_read_prepare(args.buf, path)
    end,
  })

  vim.api.nvim_create_autocmd('BufNewFile', {
    group = augroup_id,
    pattern = '*',
    callback = function(args)
      local path = normalize_path(args.match or vim.api.nvim_buf_get_name(args.buf))
      pre_read_prepare(args.buf, path)
    end,
  })

  vim.api.nvim_create_autocmd('BufEnter', {
    group = augroup_id,
    pattern = '*',
    callback = function(args) finalize_buffer(args.buf) end,
  })

  vim.api.nvim_create_autocmd('BufAdd', {
    group = augroup_id,
    pattern = '*',
    callback = function(args)
      local bufnr = args.buf
      vim.schedule(function()
        -- Later :edit calls on unreadable paths can miss the early BufReadPre/BufEnter
        -- setup used during startup. A scheduled BufAdd pass repairs that gap after the
        -- buffer exists and has finished loading enough for safe mutation.
        if not vim.api.nvim_buf_is_valid(bufnr) or not vim.api.nvim_buf_is_loaded(bufnr) then
          return
        end

        local state = buffers[bufnr]
        if state and state.renaming then return end

        local name = raw_name_of(bufnr)
        if name == '' or is_managed_buffer_name(name) or is_uri_path(name) then return end

        local state = ensure_buffer_state(bufnr)
        local path = state.path or path_of(bufnr)
        pre_read_prepare(bufnr, path)
        finalize_buffer(bufnr)
      end)
    end,
  })

  vim.api.nvim_create_autocmd('BufWipeout', {
    group = augroup_id,
    pattern = '*',
    callback = function(args) reset_runtime_state(args.buf) end,
  })
end

M._private = {
  constants = {
    MANAGED_NAME_PREFIX = MANAGED_NAME_PREFIX,
    STATE_PLAIN = STATE_PLAIN,
    STATE_CANDIDATE_READ = STATE_CANDIDATE_READ,
    STATE_CANDIDATE_WRITE = STATE_CANDIDATE_WRITE,
    STATE_MANAGED = STATE_MANAGED,
    STATE_BLOCKED_READ = STATE_BLOCKED_READ,
    STATE_UNSUPPORTED_CREATE = STATE_UNSUPPORTED_CREATE,
    STATE_UNSUPPORTED_FILETYPE = STATE_UNSUPPORTED_FILETYPE,
    STATE_UNSUPPORTED_BUFFER_MODE = STATE_UNSUPPORTED_BUFFER_MODE,
    STATE_SETUP_FAILED = STATE_SETUP_FAILED,
  },
  normalize_path = normalize_path,
  resolve_path = resolve_path,
  raw_name_of = raw_name_of,
  managed_buffer_name = managed_buffer_name,
  is_managed_buffer_name = is_managed_buffer_name,
  path_of = path_of,
  same_path_identity = same_path_identity,
  preclassify_path = preclassify_path,
  nearest_existing_parent = nearest_existing_parent,
  is_unsupported_special_path = is_unsupported_special_path,
  is_supported_fileencoding = is_supported_fileencoding,
  is_supported_buffer_mode = is_supported_buffer_mode,
  parse_text_bytes = parse_text_bytes,
  serialize_buffer = serialize_buffer,
  attach_buffer_handlers = attach_buffer_handlers,
  handle_buf_write_request = handle_buf_write_request,
  handle_file_write_request = handle_file_write_request,
  handle_buf_file_pre = handle_buf_file_pre,
  pre_read_prepare = pre_read_prepare,
  finalize_candidate_read = finalize_candidate_read,
  finalize_buffer = finalize_buffer,
  replay_read_autocmds = replay_read_autocmds,
  transition_buffer = transition_buffer,
  enter_setup_failed = enter_setup_failed,
  harden_sensitive_buffer = harden_sensitive_buffer,
  ensure_buffer_state = ensure_buffer_state,
  detach_buffer_autocmds = detach_buffer_autocmds,
  reset_runtime_state = reset_runtime_state,
  write_privileged_buffer = write_privileged_buffer,
  read_privileged_into_buffer = read_privileged_into_buffer,
  set_run_sudo_impl = function(fn) run_sudo_impl = fn end,
  reset_run_sudo_impl = function() run_sudo_impl = default_run_sudo end,
}

return M
