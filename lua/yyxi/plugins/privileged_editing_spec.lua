local assert = require('luassert')
local privileged_editing = require('yyxi.plugins.privileged_editing')

local p = privileged_editing._private
local constants = p.constants

---@param path string
---@param content string
local function write_bytes(path, content)
  local file = assert(io.open(path, 'wb'))
  assert(file:write(content))
  assert(file:close())
end

---@param path string
---@return string
local function read_bytes(path)
  local file = assert(io.open(path, 'rb'))
  local content = assert(file:read('*a'))
  assert(file:close())
  return content
end

---@param path string
---@param mode string
local function chmod(path, mode)
  local result = vim.system({ 'chmod', mode, path }):wait()
  assert.equals(0, result.code)
end

---@param target string
---@param link string
local function symlink(target, link)
  local result = vim.system({ 'ln', '-s', target, link }):wait()
  assert.equals(0, result.code)
end

---@return string
local function make_temp_dir()
  local path = vim.fn.tempname()
  assert.equals(1, vim.fn.mkdir(path, 'p'))
  return path
end

---@param path string
local function ensure_writable_tree(path)
  if vim.fn.isdirectory(path) ~= 1 then return end
  pcall(function() vim.system({ 'chmod', '-R', 'u+w', path }):wait() end)
end

---@param path string
---@return integer
local function edit_file(path)
  vim.cmd('edit ' .. vim.fn.fnameescape(path))
  return vim.api.nvim_get_current_buf()
end

---@param buffer integer
local function wipe_buffer(buffer)
  if not vim.api.nvim_buf_is_valid(buffer) then return end
  p.reset_runtime_state(buffer)
  pcall(vim.api.nvim_buf_delete, buffer, { force = true })
end

describe('yyxi.plugins.privileged_editing', function()
  local temp_dirs
  local buffers_to_wipe
  local stubs
  local augroups_to_delete

  local function stub(tbl, key, value)
    table.insert(stubs, { tbl = tbl, key = key, value = tbl[key] })
    tbl[key] = value
  end

  local function temp_path(name)
    local dir = make_temp_dir()
    table.insert(temp_dirs, dir)
    return dir, dir .. '/' .. name
  end

  before_each(function()
    temp_dirs = {}
    buffers_to_wipe = {}
    stubs = {}
    augroups_to_delete = {}
    privileged_editing.configure()
    p.reset_run_sudo_impl()
  end)

  after_each(function()
    p.reset_run_sudo_impl()

    for index = #stubs, 1, -1 do
      local entry = stubs[index]
      entry.tbl[entry.key] = entry.value
    end

    for _, group in ipairs(augroups_to_delete) do
      pcall(vim.api.nvim_del_augroup_by_id, group)
    end

    vim.cmd('enew!')
    for _, buffer in ipairs(buffers_to_wipe) do
      wipe_buffer(buffer)
    end

    for _, dir in ipairs(temp_dirs) do
      ensure_writable_tree(dir)
      pcall(vim.fn.delete, dir, 'rf')
    end
  end)

  it('keeps plain writable symlinks outside the feature', function()
    local dir, target = temp_path('target.txt')
    local link = dir .. '/target-link.txt'
    write_bytes(target, 'value\n')
    symlink(target, link)

    local result = p.preclassify_path(link)

    assert.equals(constants.STATE_PLAIN, result.kind)
  end)

  it(
    'classifies unreadable and unwritable regular files and symlinked regular-file targets consistently',
    function()
      local dir, unreadable = temp_path('unreadable.txt')
      local unwritable = dir .. '/unwritable.txt'
      local link_target = dir .. '/link-target.txt'
      local link_path = dir .. '/link-target-link.txt'

      write_bytes(unreadable, 'secret\n')
      write_bytes(unwritable, 'value\n')
      write_bytes(link_target, 'value\n')
      chmod(unreadable, '000')
      chmod(unwritable, '444')
      chmod(link_target, '444')
      symlink(link_target, link_path)

      local unreadable_result = p.preclassify_path(unreadable)
      local unwritable_result = p.preclassify_path(unwritable)
      local link_result = p.preclassify_path(link_path)

      assert.equals(constants.STATE_CANDIDATE_READ, unreadable_result.kind)
      assert.equals(constants.STATE_CANDIDATE_WRITE, unwritable_result.kind)
      assert.equals(constants.STATE_CANDIDATE_WRITE, link_result.kind)
      assert.equals('file', link_result.filetype)
    end
  )

  it('classifies permission-denied lstat regular files as candidate-read', function()
    local _, path = temp_path('hidden.txt')
    local uv = vim.uv or vim.loop
    local real_fs_lstat = uv.fs_lstat

    stub(uv, 'fs_lstat', function(candidate)
      if candidate == path then return nil, 'EACCES: permission denied: ' .. candidate, 'EACCES' end
      return real_fs_lstat(candidate)
    end)

    p.set_run_sudo_impl(function(argv)
      assert.same({ 'test', '-f', path }, argv)
      return {
        code = 0,
        signal = 0,
        stdout = '',
        stderr = '',
      }
    end)

    local result = p.preclassify_path(path)

    assert.equals(constants.STATE_CANDIDATE_READ, result.kind)
    assert.is_true(result.exists)
    assert.is_false(result.readable)
    assert.is_false(result.writable)
    assert.equals('file', result.filetype)
  end)

  it('parses errno names from lstat error strings when errname is absent', function()
    local _, path = temp_path('hidden.txt')
    local uv = vim.uv or vim.loop
    local real_fs_lstat = uv.fs_lstat

    stub(uv, 'fs_lstat', function(candidate)
      if candidate == path then return nil, 'EACCES: permission denied: ' .. candidate end
      return real_fs_lstat(candidate)
    end)

    p.set_run_sudo_impl(function(argv)
      assert.same({ 'test', '-f', path }, argv)
      return {
        code = 0,
        signal = 0,
        stdout = '',
        stderr = '',
      }
    end)

    local result = p.preclassify_path(path)

    assert.equals(constants.STATE_CANDIDATE_READ, result.kind)
    assert.is_true(result.exists)
  end)

  it(
    'classifies permission-denied lstat symlinked regular-file targets as candidate-read',
    function()
      local _, path = temp_path('hidden-link')
      local uv = vim.uv or vim.loop
      local real_fs_lstat = uv.fs_lstat

      stub(uv, 'fs_lstat', function(candidate)
        if candidate == path then
          return nil, 'EACCES: permission denied: ' .. candidate, 'EACCES'
        end
        return real_fs_lstat(candidate)
      end)

      p.set_run_sudo_impl(function(argv)
        assert.same({ 'test', '-f', path }, argv)
        return {
          code = 0,
          signal = 0,
          stdout = '',
          stderr = '',
        }
      end)

      local result = p.preclassify_path(path)

      assert.equals(constants.STATE_CANDIDATE_READ, result.kind)
      assert.equals('file', result.filetype)
    end
  )

  it('classifies broken symlinks as unsupported filetypes', function()
    local dir, target = temp_path('missing-target.txt')
    local link = dir .. '/broken-link.txt'
    symlink(target, link)

    local result = p.preclassify_path(link)

    assert.equals(constants.STATE_UNSUPPORTED_FILETYPE, result.kind)
    assert.equals('link', result.filetype)
  end)

  it('compares managed names and alias paths by underlying identity', function()
    local dir = make_temp_dir()
    local real_dir = dir .. '/real'
    local alias_dir = dir .. '/alias'
    local path = real_dir .. '/managed.txt'
    local alias_path = alias_dir .. '/managed.txt'
    local other_path = real_dir .. '/other.txt'
    table.insert(temp_dirs, dir)
    assert.equals(1, vim.fn.mkdir(real_dir, 'p'))
    symlink(real_dir, alias_dir)
    write_bytes(path, 'value\n')
    write_bytes(other_path, 'other\n')

    assert.is_true(p.same_path_identity(p.managed_buffer_name(path), alias_path))
    assert.is_true(p.same_path_identity(path, alias_path))
    assert.is_false(p.same_path_identity(p.managed_buffer_name(path), other_path))
  end)

  it('falls back to candidate-read when permission-denied probing stays inconclusive', function()
    local _, path = temp_path('hidden.txt')
    local uv = vim.uv or vim.loop
    local real_fs_lstat = uv.fs_lstat

    stub(uv, 'fs_lstat', function(candidate)
      if candidate == path then return nil, 'EACCES: permission denied: ' .. candidate, 'EACCES' end
      return real_fs_lstat(candidate)
    end)

    p.set_run_sudo_impl(function(argv)
      assert.same({ 'test', '-f', path }, argv)
      return {
        code = 2,
        signal = 0,
        stdout = '',
        stderr = '',
      }
    end)

    local result = p.preclassify_path(path)

    assert.equals(constants.STATE_CANDIDATE_READ, result.kind)
    assert.is_true(result.exists)
    assert.is_false(result.readable)
    assert.is_false(result.writable)
  end)

  it(
    'keeps candidate-read when permission-denied existence probing is blocked by locked sudo',
    function()
      local _, path = temp_path('hidden.txt')
      local uv = vim.uv or vim.loop
      local real_fs_lstat = uv.fs_lstat

      stub(uv, 'fs_lstat', function(candidate)
        if candidate == path then
          return nil, 'EACCES: permission denied: ' .. candidate, 'EACCES'
        end
        return real_fs_lstat(candidate)
      end)

      p.set_run_sudo_impl(function(argv)
        if argv[1] == 'test' then
          return {
            code = 1,
            signal = 0,
            stdout = '',
            stderr = 'sudo: a password is required',
          }
        end

        assert.same({ 'true' }, argv)
        return {
          code = 1,
          signal = 0,
          stdout = '',
          stderr = 'sudo: a password is required',
        }
      end)

      local result = p.preclassify_path(path)

      assert.equals(constants.STATE_CANDIDATE_READ, result.kind)
      assert.is_true(result.exists)
    end
  )

  it('classifies missing paths behind permission-denied traversal as unsupported create', function()
    local _, path = temp_path('missing.txt')
    local uv = vim.uv or vim.loop
    local real_fs_lstat = uv.fs_lstat

    stub(uv, 'fs_lstat', function(candidate)
      if candidate == path then return nil, 'EACCES: permission denied: ' .. candidate, 'EACCES' end
      return real_fs_lstat(candidate)
    end)

    p.set_run_sudo_impl(function(argv)
      if vim.deep_equal(argv, { 'test', '-f', path }) then
        return {
          code = 1,
          signal = 0,
          stdout = '',
          stderr = '',
        }
      end

      if vim.deep_equal(argv, { 'test', '-d', path }) then
        return {
          code = 1,
          signal = 0,
          stdout = '',
          stderr = '',
        }
      end

      if vim.deep_equal(argv, { 'test', '-L', path }) then
        return {
          code = 1,
          signal = 0,
          stdout = '',
          stderr = '',
        }
      end

      if vim.deep_equal(argv, { 'test', '-e', path }) then
        return {
          code = 1,
          signal = 0,
          stdout = '',
          stderr = '',
        }
      end

      assert.same({ 'true' }, argv)
      return {
        code = 0,
        signal = 0,
        stdout = '',
        stderr = '',
      }
    end)

    local result = p.preclassify_path(path)

    assert.equals(constants.STATE_UNSUPPORTED_CREATE, result.kind)
    assert.is_false(result.exists)
  end)

  it('loads permission-denied lstat regular files through the privileged read flow', function()
    local _, path = temp_path('hidden.txt')
    local uv = vim.uv or vim.loop
    local real_fs_lstat = uv.fs_lstat

    stub(uv, 'fs_lstat', function(candidate)
      if candidate == path then return nil, 'EACCES: permission denied: ' .. candidate, 'EACCES' end
      return real_fs_lstat(candidate)
    end)

    p.set_run_sudo_impl(function(argv)
      if vim.deep_equal(argv, { 'test', '-f', path }) then
        return {
          code = 0,
          signal = 0,
          stdout = '',
          stderr = '',
        }
      end

      assert.same({ 'cat', path }, argv)
      return {
        code = 0,
        signal = 0,
        stdout = 'loaded through probe\n',
        stderr = '',
      }
    end)

    local buffer = vim.api.nvim_create_buf(true, false)
    table.insert(buffers_to_wipe, buffer)
    vim.api.nvim_set_current_buf(buffer)
    vim.api.nvim_buf_set_name(buffer, path)

    p.pre_read_prepare(buffer, path)
    p.finalize_buffer(buffer)

    assert.equals(constants.STATE_MANAGED, vim.b[buffer].privileged_editing_state)
    assert.equals(p.managed_buffer_name(path), vim.api.nvim_buf_get_name(buffer))
    assert.same({ 'loaded through probe' }, vim.api.nvim_buf_get_lines(buffer, 0, -1, false))
  end)

  it('keeps unsupported filetypes under module-controlled write rejection', function()
    local dir, target = temp_path('missing-target.txt')
    local link = dir .. '/broken-link.txt'
    symlink(target, link)

    local buffer = vim.api.nvim_create_buf(true, false)
    table.insert(buffers_to_wipe, buffer)
    vim.api.nvim_set_current_buf(buffer)
    vim.api.nvim_buf_set_name(buffer, link)

    p.pre_read_prepare(buffer, link)
    p.finalize_buffer(buffer)

    assert.equals(constants.STATE_UNSUPPORTED_FILETYPE, vim.b[buffer].privileged_editing_state)
    assert.equals(p.managed_buffer_name(link), vim.api.nvim_buf_get_name(buffer))

    local errors = {}
    stub(vim.api, 'nvim_err_writeln', function(message) table.insert(errors, message) end)

    local ok, message = p.handle_buf_write_request(buffer, vim.api.nvim_buf_get_name(buffer))

    assert.is_false(ok)
    assert.matches('unsupported for non%-regular path', message)
    assert.same({ message }, errors)
  end)

  it('classifies missing files under protected parents as unsupported create', function()
    local dir = make_temp_dir()
    local protected = dir .. '/protected'
    table.insert(temp_dirs, dir)
    assert.equals(1, vim.fn.mkdir(protected, 'p'))
    chmod(protected, '555')

    local result = p.preclassify_path(protected .. '/newfile.conf')

    assert.equals(constants.STATE_UNSUPPORTED_CREATE, result.kind)
  end)

  it('parses missing-path errno names from lstat error strings when errname is absent', function()
    local _, path = temp_path('missing.txt')
    local uv = vim.uv or vim.loop
    local real_fs_lstat = uv.fs_lstat

    stub(uv, 'fs_lstat', function(candidate)
      if candidate == path then return nil, 'ENOENT: no such file or directory: ' .. candidate end
      return real_fs_lstat(candidate)
    end)

    local result = p.preclassify_path(path)

    assert.equals(constants.STATE_PLAIN, result.kind)
    assert.is_false(result.exists)
    assert.is_true(result.writable)
  end)

  it('keeps unsupported create under module-controlled write rejection', function()
    local dir = make_temp_dir()
    local protected = dir .. '/protected'
    local path = protected .. '/newfile.conf'
    table.insert(temp_dirs, dir)
    assert.equals(1, vim.fn.mkdir(protected, 'p'))
    chmod(protected, '555')

    local buffer = vim.api.nvim_create_buf(true, false)
    table.insert(buffers_to_wipe, buffer)
    vim.api.nvim_set_current_buf(buffer)
    vim.api.nvim_buf_set_name(buffer, path)

    p.pre_read_prepare(buffer, path)
    p.finalize_buffer(buffer)

    assert.equals(constants.STATE_UNSUPPORTED_CREATE, vim.b[buffer].privileged_editing_state)
    assert.equals(p.managed_buffer_name(path), vim.api.nvim_buf_get_name(buffer))

    local errors = {}
    stub(vim.api, 'nvim_err_writeln', function(message) table.insert(errors, message) end)

    local ok, message = p.handle_buf_write_request(buffer, vim.api.nvim_buf_get_name(buffer))

    assert.is_false(ok)
    assert.matches('create is unsupported', message)
    assert.same({ message }, errors)
  end)

  it('parses unix, dos, mac, and empty privileged read payloads', function()
    local unix = assert(p.parse_text_bytes('alpha\nbeta', 'unix'))
    local dos = assert(p.parse_text_bytes('alpha\r\nbeta\r\n', 'unix'))
    local mac = assert(p.parse_text_bytes('alpha\rbeta', 'unix'))
    local empty = assert(p.parse_text_bytes('', 'unix'))

    assert.same({ 'alpha', 'beta' }, unix.lines)
    assert.equals('unix', unix.fileformat)
    assert.is_false(unix.endofline)

    assert.same({ 'alpha', 'beta' }, dos.lines)
    assert.equals('dos', dos.fileformat)
    assert.is_true(dos.endofline)

    assert.same({ 'alpha', 'beta' }, mac.lines)
    assert.equals('mac', mac.fileformat)
    assert.is_false(mac.endofline)

    assert.same({ '' }, empty.lines)
    assert.equals('unix', empty.fileformat)
    assert.is_true(empty.endofline)
  end)

  it('rejects invalid utf-8 privileged read payloads', function()
    local parsed, message = p.parse_text_bytes(string.char(0xFF), 'unix')

    assert.is_nil(parsed)
    assert.matches('invalid UTF%-8', message)
  end)

  it('rejects NUL bytes before utf-8 validation', function()
    local parsed, message = p.parse_text_bytes(string.char(0x00), 'unix')

    assert.is_nil(parsed)
    assert.matches('NUL bytes', message)
  end)

  it('serializes supported buffers using fileformat and end-of-line state', function()
    local buffer = vim.api.nvim_create_buf(true, true)
    table.insert(buffers_to_wipe, buffer)
    vim.api.nvim_set_current_buf(buffer)

    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { 'alpha', 'beta' })
    vim.bo[buffer].fileformat = 'dos'
    vim.bo[buffer].fixendofline = false
    vim.bo[buffer].endofline = false
    assert.equals('alpha\r\nbeta', p.serialize_buffer(buffer))

    vim.bo[buffer].fileformat = 'unix'
    vim.bo[buffer].fixendofline = true
    vim.bo[buffer].endofline = false
    assert.equals('alpha\nbeta\n', p.serialize_buffer(buffer))
  end)

  it('hardens candidate buffers before contents are loaded', function()
    local _, path = temp_path('readonly.txt')
    write_bytes(path, 'value\n')
    chmod(path, '444')

    local buffer = vim.api.nvim_create_buf(true, false)
    table.insert(buffers_to_wipe, buffer)
    vim.api.nvim_buf_set_name(buffer, path)
    vim.bo[buffer].swapfile = true
    vim.bo[buffer].undofile = true

    p.pre_read_prepare(buffer, path)

    assert.is_false(vim.bo[buffer].swapfile)
    assert.is_false(vim.bo[buffer].undofile)
    assert.equals(constants.STATE_CANDIDATE_WRITE, vim.b[buffer].privileged_editing_state)
  end)

  it('loads privileged read content and applies newline metadata', function()
    local _, path = temp_path('root-owned.txt')
    local buffer = vim.api.nvim_create_buf(true, false)
    table.insert(buffers_to_wipe, buffer)
    vim.api.nvim_buf_set_name(buffer, path)
    vim.api.nvim_set_current_buf(buffer)

    p.set_run_sudo_impl(function(argv)
      assert.same({ 'cat', path }, argv)
      return {
        code = 0,
        signal = 0,
        stdout = 'alpha\r\nbeta',
        stderr = '',
      }
    end)

    local ok, message = p.read_privileged_into_buffer(buffer, path)

    assert.is_true(ok)
    assert.equals('Privileged read succeeded for ' .. path .. '.', message)
    assert.same({ 'alpha', 'beta' }, vim.api.nvim_buf_get_lines(buffer, 0, -1, false))
    assert.equals('dos', vim.bo[buffer].fileformat)
    assert.is_false(vim.bo[buffer].endofline)
    assert.is_false(vim.bo[buffer].modified)
  end)

  it('supports later :edit of unreadable regular files through BufAdd finalization', function()
    local _, path = temp_path('root-owned-later.txt')
    write_bytes(path, 'secret\n')
    chmod(path, '000')

    p.set_run_sudo_impl(function(argv)
      if argv[1] == 'cat' then
        return {
          code = 0,
          signal = 0,
          stdout = 'loaded later\n',
          stderr = '',
        }
      end

      return {
        code = 0,
        signal = 0,
        stdout = '',
        stderr = '',
      }
    end)

    local buffer = edit_file(path)
    table.insert(buffers_to_wipe, buffer)
    assert.is_true(
      vim.wait(100, function() return vim.b[buffer].privileged_editing_state ~= nil end)
    )

    assert.equals(constants.STATE_MANAGED, vim.b[buffer].privileged_editing_state)
    assert.is_true(p.is_managed_buffer_name(vim.api.nvim_buf_get_name(buffer)))
    assert.is_true(p.same_path_identity(p.path_of(buffer), path))
    assert.same({ 'loaded later' }, vim.api.nvim_buf_get_lines(buffer, 0, -1, false))
  end)

  it(
    'supports later :edit of unreadable unsupported filetypes through BufAdd finalization',
    function()
      local _, path = temp_path('named-pipe')
      local result = vim.system({ 'mkfifo', path }):wait()
      assert.equals(0, result.code)
      chmod(path, '000')

      local buffer = edit_file(path)
      table.insert(buffers_to_wipe, buffer)
      assert.is_true(
        vim.wait(100, function() return vim.b[buffer].privileged_editing_state ~= nil end)
      )

      assert.equals(constants.STATE_UNSUPPORTED_FILETYPE, vim.b[buffer].privileged_editing_state)
      assert.is_true(p.is_managed_buffer_name(vim.api.nvim_buf_get_name(buffer)))
      assert.is_true(p.same_path_identity(p.path_of(buffer), path))
    end
  )

  it('does not reread already-loaded privileged contents on later finalization', function()
    local _, path = temp_path('root-owned.txt')
    write_bytes(path, 'secret\n')
    chmod(path, '000')

    local read_calls = 0
    p.set_run_sudo_impl(function(argv)
      if argv[1] == 'cat' then
        read_calls = read_calls + 1
        return {
          code = 0,
          signal = 0,
          stdout = 'loaded once\n',
          stderr = '',
        }
      end

      return {
        code = 0,
        signal = 0,
        stdout = '',
        stderr = '',
      }
    end)

    local buffer = vim.api.nvim_create_buf(true, false)
    table.insert(buffers_to_wipe, buffer)
    vim.api.nvim_set_current_buf(buffer)
    vim.api.nvim_buf_set_name(buffer, path)

    p.finalize_candidate_read(buffer, path)
    p.finalize_buffer(buffer)

    assert.equals(1, read_calls)
    assert.equals(constants.STATE_MANAGED, vim.b[buffer].privileged_editing_state)
    assert.same({ 'loaded once' }, vim.api.nvim_buf_get_lines(buffer, 0, -1, false))
  end)

  it('replays read autocommands and filetype detection for privileged reads', function()
    local _, path = temp_path('root-owned.lua')
    write_bytes(path, 'print("ignored")\n')

    local group = vim.api.nvim_create_augroup(
      'PrivilegedEditingSpecRead' .. tostring((vim.uv or vim.loop).hrtime()),
      { clear = true }
    )
    table.insert(augroups_to_delete, group)
    vim.api.nvim_create_autocmd('BufReadPost', {
      group = group,
      pattern = '*.lua',
      callback = function(args) vim.b[args.buf].privileged_editing_test_bufreadpost = true end,
    })

    p.set_run_sudo_impl(function(argv)
      if argv[1] == 'cat' then
        return {
          code = 0,
          signal = 0,
          stdout = 'print("ok")\n',
          stderr = '',
        }
      end

      return {
        code = 0,
        signal = 0,
        stdout = '',
        stderr = '',
      }
    end)

    local buffer = vim.api.nvim_create_buf(true, false)
    table.insert(buffers_to_wipe, buffer)
    vim.api.nvim_set_current_buf(buffer)
    vim.api.nvim_buf_set_name(buffer, path)

    p.finalize_candidate_read(buffer, path)

    assert.equals(constants.STATE_MANAGED, vim.b[buffer].privileged_editing_state)
    assert.equals('lua', vim.bo[buffer].filetype)
    assert.is_true(vim.b[buffer].privileged_editing_test_bufreadpost)
    assert.equals(p.managed_buffer_name(path), vim.api.nvim_buf_get_name(buffer))
    assert.same({ 'print("ok")' }, vim.api.nvim_buf_get_lines(buffer, 0, -1, false))
  end)

  it('keeps blocked privileged reads on the real path when sudo read fails', function()
    local _, path = temp_path('blocked.txt')
    write_bytes(path, 'secret\n')

    p.set_run_sudo_impl(function(argv)
      if argv[1] == 'cat' then
        return {
          code = 1,
          signal = 0,
          stdout = '',
          stderr = 'permission denied',
        }
      end

      return {
        code = 1,
        signal = 0,
        stdout = '',
        stderr = 'a password is required',
      }
    end)

    local buffer = vim.api.nvim_create_buf(true, false)
    table.insert(buffers_to_wipe, buffer)
    vim.api.nvim_set_current_buf(buffer)
    vim.api.nvim_buf_set_name(buffer, path)

    p.finalize_candidate_read(buffer, path)

    assert.equals(constants.STATE_BLOCKED_READ, vim.b[buffer].privileged_editing_state)
    assert.is_true(p.same_path_identity(vim.api.nvim_buf_get_name(buffer), path))
    assert.is_true(vim.bo[buffer].readonly)
    assert.is_false(vim.bo[buffer].modifiable)
    assert.matches('permission denied', vim.b[buffer].privileged_editing_reason)
    assert.matches('Preauthorize', vim.b[buffer].privileged_editing_reason)
  end)

  it('does not retry a blocked read on plain BufEnter without an explicit reread', function()
    local _, path = temp_path('blocked.txt')
    write_bytes(path, 'secret\n')

    p.set_run_sudo_impl(function(argv)
      if argv[1] == 'cat' then
        return {
          code = 1,
          signal = 0,
          stdout = '',
          stderr = 'permission denied',
        }
      end

      return {
        code = 1,
        signal = 0,
        stdout = '',
        stderr = 'a password is required',
      }
    end)

    local buffer = vim.api.nvim_create_buf(true, false)
    table.insert(buffers_to_wipe, buffer)
    vim.api.nvim_set_current_buf(buffer)
    vim.api.nvim_buf_set_name(buffer, path)

    p.finalize_candidate_read(buffer, path)

    p.set_run_sudo_impl(function(argv)
      if argv[1] == 'cat' then
        return {
          code = 0,
          signal = 0,
          stdout = 'loaded later\n',
          stderr = '',
        }
      end

      return {
        code = 0,
        signal = 0,
        stdout = '',
        stderr = '',
      }
    end)

    p.finalize_buffer(buffer)

    assert.equals(constants.STATE_BLOCKED_READ, vim.b[buffer].privileged_editing_state)
    assert.same({ '' }, vim.api.nvim_buf_get_lines(buffer, 0, -1, false))
  end)

  it('serializes privileged writes through tee without temporary files', function()
    local _, path = temp_path('existing.txt')
    write_bytes(path, 'orig\n')

    local buffer = edit_file(path)
    table.insert(buffers_to_wipe, buffer)
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { 'alpha', 'beta' })
    vim.bo[buffer].fileformat = 'mac'
    vim.bo[buffer].fixendofline = false
    vim.bo[buffer].endofline = false

    local observed = {}
    p.set_run_sudo_impl(function(argv, opts)
      observed.argv = argv
      observed.stdin = opts.stdin
      write_bytes(path, opts.stdin)
      return {
        code = 0,
        signal = 0,
        stdout = '',
        stderr = '',
      }
    end)

    local ok, message = p.write_privileged_buffer(buffer, path)

    assert.is_true(ok)
    assert.equals('Privileged write succeeded for ' .. path .. '.', message)
    assert.same({ 'tee', path }, observed.argv)
    assert.equals('alpha\rbeta', observed.stdin)
    assert.equals('alpha\rbeta', read_bytes(path))
  end)

  it('rejects privileged writes after the buffer mode becomes unsupported', function()
    local _, path = temp_path('managed.txt')
    write_bytes(path, 'orig\n')
    chmod(path, '444')

    local buffer = edit_file(path)
    table.insert(buffers_to_wipe, buffer)
    vim.bo[buffer].binary = true

    local errors = {}
    stub(vim.api, 'nvim_err_writeln', function(message) table.insert(errors, message) end)

    local ok, message = p.handle_buf_write_request(buffer, vim.api.nvim_buf_get_name(buffer))

    assert.is_false(ok)
    assert.equals(
      'Privileged editing is limited to UTF-8 text buffers with binary mode off.',
      message
    )
    assert.same({ message }, errors)
    assert.equals('orig\n', read_bytes(path))
  end)

  it('rejects alternate-path whole-buffer writes through BufWriteCmd dispatch', function()
    local dir, path = temp_path('managed.txt')
    local other = dir .. '/other.txt'
    write_bytes(path, 'orig\n')

    local buffer = edit_file(path)
    table.insert(buffers_to_wipe, buffer)
    local state = p.ensure_buffer_state(buffer)
    state.kind = constants.STATE_CANDIDATE_WRITE
    state.path = p.normalize_path(path)

    local errors = {}
    stub(vim.api, 'nvim_err_writeln', function(message) table.insert(errors, message) end)

    local ok, message = p.handle_buf_write_request(buffer, other)

    assert.is_false(ok)
    assert.matches('alternate%-path write is unsupported', message)
    assert.same({ message }, errors)
  end)

  it('allows alias-equivalent whole-buffer writes through BufWriteCmd dispatch', function()
    local dir = make_temp_dir()
    local real_dir = dir .. '/real'
    local alias_dir = dir .. '/alias'
    local path = real_dir .. '/managed.txt'
    local alias_path = alias_dir .. '/managed.txt'
    table.insert(temp_dirs, dir)
    assert.equals(1, vim.fn.mkdir(real_dir, 'p'))
    symlink(real_dir, alias_dir)
    write_bytes(path, 'orig\n')
    chmod(path, '444')

    local buffer = edit_file(path)
    table.insert(buffers_to_wipe, buffer)
    local state = p.ensure_buffer_state(buffer)
    state.kind = constants.STATE_CANDIDATE_WRITE
    state.path = p.normalize_path(path)
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { 'changed' })

    local observed = {}
    p.set_run_sudo_impl(function(argv, opts)
      observed.argv = argv
      observed.stdin = opts.stdin
      chmod(path, '644')
      write_bytes(path, opts.stdin)
      return {
        code = 0,
        signal = 0,
        stdout = '',
        stderr = '',
      }
    end)

    local ok, message = p.handle_buf_write_request(buffer, alias_path)

    assert.is_true(ok)
    assert.equals('Privileged write succeeded for ' .. p.normalize_path(path) .. '.', message)
    assert.same({ 'tee', p.normalize_path(path) }, observed.argv)
    assert.equals('changed\n', observed.stdin)
    assert.equals('changed\n', read_bytes(path))
    assert.is_true(p.same_path_identity(alias_path, path))
  end)

  it('rejects saveas before managed-path mutation', function()
    local dir, path = temp_path('managed.txt')
    local other = dir .. '/other.txt'
    write_bytes(path, 'orig\n')

    local buffer = edit_file(path)
    table.insert(buffers_to_wipe, buffer)
    local state = p.ensure_buffer_state(buffer)
    state.kind = constants.STATE_CANDIDATE_WRITE
    state.path = p.normalize_path(path)

    local errors = {}
    stub(vim.api, 'nvim_err_writeln', function(message) table.insert(errors, message) end)

    local ok, message = p.handle_buf_file_pre(buffer)

    assert.is_false(ok)
    assert.matches('path mutation is unsupported', message)
    assert.same({ message }, errors)
    assert.equals(p.normalize_path(path), state.path)
    assert.is_true(p.same_path_identity(p.path_of(buffer), path))
    assert.equals(0, vim.fn.filereadable(other))
  end)

  it('restores swapfile and undofile when a managed buffer becomes plain again', function()
    local dir, managed_path = temp_path('managed.txt')
    local plain_path = dir .. '/plain.txt'
    write_bytes(managed_path, 'managed\n')
    write_bytes(plain_path, 'plain\n')
    chmod(managed_path, '444')

    local notifications = {}
    stub(
      vim,
      'notify',
      function(message, level) table.insert(notifications, { message = message, level = level }) end
    )

    local buffer = vim.api.nvim_create_buf(true, false)
    table.insert(buffers_to_wipe, buffer)
    vim.api.nvim_set_current_buf(buffer)
    vim.api.nvim_buf_set_name(buffer, managed_path)
    vim.bo[buffer].swapfile = true
    vim.bo[buffer].undofile = true

    p.pre_read_prepare(buffer, managed_path)

    assert.is_false(vim.bo[buffer].swapfile)
    assert.is_false(vim.bo[buffer].undofile)

    vim.api.nvim_buf_set_name(buffer, plain_path)
    p.finalize_buffer(buffer)

    assert.equals(constants.STATE_PLAIN, vim.b[buffer].privileged_editing_state)
    assert.is_true(vim.bo[buffer].swapfile)
    assert.is_true(vim.bo[buffer].undofile)
    assert.is_true(p.same_path_identity(vim.api.nvim_buf_get_name(buffer), plain_path))
    assert.same({}, notifications)
  end)

  it('suppresses info notifications by default', function()
    local _, path = temp_path('managed.txt')
    write_bytes(path, 'value\n')
    chmod(path, '444')

    local notifications = {}
    stub(
      vim,
      'notify',
      function(message, level) table.insert(notifications, { message = message, level = level }) end
    )

    local buffer = vim.api.nvim_create_buf(true, false)
    table.insert(buffers_to_wipe, buffer)
    vim.api.nvim_set_current_buf(buffer)
    vim.api.nvim_buf_set_name(buffer, path)

    p.pre_read_prepare(buffer, path)
    p.finalize_buffer(buffer)

    assert.equals(constants.STATE_CANDIDATE_WRITE, vim.b[buffer].privileged_editing_state)
    assert.same({}, notifications)
  end)

  it('emits info notifications when configured at INFO', function()
    local _, path = temp_path('managed.txt')
    write_bytes(path, 'value\n')
    chmod(path, '444')

    privileged_editing.configure({ log_level = vim.log.levels.INFO })

    local notifications = {}
    stub(
      vim,
      'notify',
      function(message, level) table.insert(notifications, { message = message, level = level }) end
    )

    local buffer = vim.api.nvim_create_buf(true, false)
    table.insert(buffers_to_wipe, buffer)
    vim.api.nvim_set_current_buf(buffer)
    vim.api.nvim_buf_set_name(buffer, path)

    p.pre_read_prepare(buffer, path)
    p.finalize_buffer(buffer)

    assert.equals(constants.STATE_CANDIDATE_WRITE, vim.b[buffer].privileged_editing_state)
    assert.equals(1, #notifications)
    assert.equals(vim.log.levels.INFO, notifications[1].level)
    assert.matches('Privileged write enabled', notifications[1].message)
  end)

  it('keeps warnings visible at the default WARN log level', function()
    local _, path = temp_path('managed.txt')

    local notifications = {}
    stub(
      vim,
      'notify',
      function(message, level) table.insert(notifications, { message = message, level = level }) end
    )

    local buffer = vim.api.nvim_create_buf(true, false)
    table.insert(buffers_to_wipe, buffer)
    vim.api.nvim_set_current_buf(buffer)

    local ok, reason = p.enter_setup_failed(buffer, path, 'rename failed')

    assert.is_false(ok)
    assert.matches('setup failed', reason)
    assert.equals(1, #notifications)
    assert.equals(vim.log.levels.WARN, notifications[1].level)
    assert.matches('setup failed', notifications[1].message)
  end)

  it('gates privileged write success echo behind the INFO log level', function()
    local dir, warn_path = temp_path('managed-warn.txt')
    local info_path = dir .. '/managed-info.txt'
    write_bytes(warn_path, 'orig\n')
    write_bytes(info_path, 'orig\n')
    chmod(warn_path, '444')
    chmod(info_path, '444')

    local echoes = {}
    stub(vim.api, 'nvim_echo', function(chunks) table.insert(echoes, chunks) end)

    p.set_run_sudo_impl(function(argv, opts)
      if argv[1] == 'tee' then
        chmod(argv[2], '644')
        write_bytes(argv[2], opts.stdin)
        return {
          code = 0,
          signal = 0,
          stdout = '',
          stderr = '',
        }
      end

      return {
        code = 0,
        signal = 0,
        stdout = '',
        stderr = '',
      }
    end)

    local warn_buffer = edit_file(warn_path)
    table.insert(buffers_to_wipe, warn_buffer)
    vim.api.nvim_buf_set_lines(warn_buffer, 0, -1, false, { 'changed' })

    vim.cmd('write')

    assert.same({}, echoes)
    assert.equals('changed\n', read_bytes(warn_path))

    privileged_editing.configure({ log_level = vim.log.levels.INFO })

    local info_buffer = edit_file(info_path)
    table.insert(buffers_to_wipe, info_buffer)
    vim.api.nvim_buf_set_lines(info_buffer, 0, -1, false, { 'changed again' })

    vim.cmd('write')

    local saw_privileged_success = false
    for _, chunks in ipairs(echoes) do
      if chunks[1] and type(chunks[1][1]) == 'string' then
        if chunks[1][1]:match('Privileged write succeeded') then
          saw_privileged_success = true
          break
        end
      end
    end

    assert.is_true(saw_privileged_success)
    assert.equals('changed again\n', read_bytes(info_path))
  end)

  it('keeps privileged-related unsupported states under managed-name rejection control', function()
    local _, path = temp_path('root-owned.txt')
    write_bytes(path, 'value\n')

    local group = vim.api.nvim_create_augroup(
      'PrivilegedEditingSpecUnsupported' .. tostring((vim.uv or vim.loop).hrtime()),
      { clear = true }
    )
    table.insert(augroups_to_delete, group)
    vim.api.nvim_create_autocmd('BufReadPost', {
      group = group,
      pattern = '*.txt',
      callback = function(args) vim.bo[args.buf].binary = true end,
    })

    p.set_run_sudo_impl(function(argv)
      if argv[1] == 'cat' then
        return {
          code = 0,
          signal = 0,
          stdout = 'value\n',
          stderr = '',
        }
      end

      return {
        code = 0,
        signal = 0,
        stdout = '',
        stderr = '',
      }
    end)

    local buffer = vim.api.nvim_create_buf(true, false)
    table.insert(buffers_to_wipe, buffer)
    vim.api.nvim_set_current_buf(buffer)
    vim.api.nvim_buf_set_name(buffer, path)

    p.finalize_candidate_read(buffer, path)

    assert.equals(constants.STATE_UNSUPPORTED_BUFFER_MODE, vim.b[buffer].privileged_editing_state)
    assert.equals(p.managed_buffer_name(path), vim.api.nvim_buf_get_name(buffer))
  end)

  it('enters setup-failed instead of silently clearing to plain when rename-back fails', function()
    local _, path = temp_path('plain.txt')
    write_bytes(path, 'plain\n')

    local buffer = vim.api.nvim_create_buf(true, false)
    table.insert(buffers_to_wipe, buffer)
    vim.api.nvim_set_current_buf(buffer)
    assert.is_true(p.transition_buffer(buffer, {
      kind = constants.STATE_MANAGED,
      path = path,
      reason = nil,
      name_mode = 'managed',
      sensitive = true,
      attach_handlers = true,
      modifiable = true,
      readonly = false,
    }))

    local original_set_name = vim.api.nvim_buf_set_name
    stub(vim.api, 'nvim_buf_set_name', function(bufnr, name)
      if name == p.normalize_path(path) then error('rename back failed') end
      return original_set_name(bufnr, name)
    end)

    p.finalize_buffer(buffer)

    assert.equals(constants.STATE_SETUP_FAILED, vim.b[buffer].privileged_editing_state)
    assert.equals(p.managed_buffer_name(path), vim.api.nvim_buf_get_name(buffer))
    assert.matches('setup failed', vim.b[buffer].privileged_editing_reason)
  end)

  it('rejects invalid log levels', function()
    assert.has_error(function() privileged_editing.configure({ log_level = 'warn' }) end)
  end)

  it('supports :wall across plain and privileged-write buffers', function()
    local dir, plain_path = temp_path('plain.txt')
    local privileged_path = dir .. '/privileged.txt'
    write_bytes(plain_path, 'plain\n')
    write_bytes(privileged_path, 'privileged\n')
    chmod(privileged_path, '444')

    p.set_run_sudo_impl(function(argv, opts)
      if argv[1] == 'tee' then
        chmod(argv[2], '644')
        write_bytes(argv[2], opts.stdin)
        return {
          code = 0,
          signal = 0,
          stdout = '',
          stderr = '',
        }
      end

      return {
        code = 0,
        signal = 0,
        stdout = '',
        stderr = '',
      }
    end)

    local plain_buffer = edit_file(plain_path)
    table.insert(buffers_to_wipe, plain_buffer)
    vim.api.nvim_buf_set_lines(plain_buffer, 0, -1, false, { 'plain changed' })

    local privileged_buffer = edit_file(privileged_path)
    table.insert(buffers_to_wipe, privileged_buffer)
    vim.api.nvim_buf_set_lines(privileged_buffer, 0, -1, false, { 'privileged changed' })

    assert.is_false(vim.bo[privileged_buffer].readonly)
    assert.equals(
      constants.STATE_CANDIDATE_WRITE,
      vim.b[privileged_buffer].privileged_editing_state
    )
    assert.is_true(p.is_managed_buffer_name(vim.api.nvim_buf_get_name(privileged_buffer)))
    assert.is_true(p.same_path_identity(p.path_of(privileged_buffer), privileged_path))

    vim.cmd('wall')

    assert.equals('plain changed\n', read_bytes(plain_path))
    assert.equals('privileged changed\n', read_bytes(privileged_path))
    assert.is_false(vim.bo[plain_buffer].modified)
    assert.is_false(vim.bo[privileged_buffer].modified)
  end)
end)
