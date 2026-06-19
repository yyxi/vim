local M = {}

local DEFAULT_FILE_PAGE_SIZE = 200
local DEFAULT_GREP_PAGE_SIZE = 200
local DEFAULT_WAIT_FOR_INDEX_MS = 10000

---@param opts? table
---@return string
function M.picker_cwd(opts)
  local cwd = (opts and opts.cwd) or vim.uv.cwd()
  if type(cwd) ~= 'string' or cwd == '' then cwd = '.' end
  return vim.fn.fnamemodify(vim.fn.expand(cwd), ':p')
end

---@param opts table?
---@param names string[]
---@return boolean
local function has_any_option(opts, names)
  if type(opts) ~= 'table' then return false end
  for _, name in ipairs(names) do
    if opts[name] ~= nil then return true end
  end
  return false
end

function M._load_fff() return pcall(require, 'fff') end

function M._prepare_fff_runtime()
  local ok, file_picker = pcall(require, 'fff.file_picker')
  if not ok then error(file_picker) end

  local setup_ok, setup_result = pcall(file_picker.setup)
  if not setup_ok or setup_result ~= true then
    error(setup_result or 'FFF file picker setup failed')
  end
end

---@param opts? table
---@return boolean
function M.fff_health_ok(opts)
  local ok, fuzzy = pcall(require, 'fff.fuzzy')
  if not ok then return false end

  local health_ok, health = pcall(fuzzy.health_check, M.picker_cwd(opts))
  if not health_ok or type(health) ~= 'table' then return false end

  local file_picker = health.file_picker
  return type(file_picker) == 'table' and file_picker.initialized == true
end

function M._require_telescope()
  return {
    builtin = require('telescope.builtin'),
    conf = require('telescope.config').values,
    finders = require('telescope.finders'),
    make_entry = require('telescope.make_entry'),
    pickers = require('telescope.pickers'),
    sorters = require('telescope.sorters'),
  }
end

---@param opts? table
---@return table
function M.telescope_picker_opts(opts)
  return vim.tbl_extend('keep', { cwd = M.picker_cwd(opts) }, opts or {})
end

---@param opts? table
---@return table?
function M.resolve_fff_backend(opts)
  local ok, fff = M._load_fff()
  if not ok then return nil end

  local prepared = pcall(M._prepare_fff_runtime)
  if not prepared then return nil end

  if not M.fff_health_ok(opts) then return nil end
  return fff
end

---@param result table?
---@return string[]
function M._file_search_lines(result)
  local items = type(result) == 'table' and result.items or nil
  if type(items) ~= 'table' then return {} end

  local lines = {}
  for _, item in ipairs(items) do
    if
      type(item) == 'table'
      and type(item.relative_path) == 'string'
      and item.relative_path ~= ''
    then
      table.insert(lines, item.relative_path)
    end
  end
  return lines
end

---@param result table?
---@return string[]
function M._grep_result_lines(result)
  local items = type(result) == 'table' and result.items or nil
  if type(items) ~= 'table' then return {} end

  local lines = {}
  for _, item in ipairs(items) do
    if
      type(item) == 'table'
      and type(item.relative_path) == 'string'
      and item.relative_path ~= ''
    then
      local lnum = tonumber(item.line_number) or 1
      local col = (tonumber(item.col) or 0) + 1
      local text = type(item.line_content) == 'string' and item.line_content or ''
      table.insert(lines, string.format('%s:%d:%d:%s', item.relative_path, lnum, col, text))
    end
  end
  return lines
end

---@param opts? table
---@return "plain"|"regex"
function M._grep_mode_for_grep_string(opts) return opts and opts.use_regex and 'regex' or 'plain' end

---@param opts? table
---@return string
function M._grep_string_query(opts)
  if opts and type(opts.search) == 'string' and opts.search ~= '' then return opts.search end

  if vim.fn.mode() == 'v' then
    local saved_reg = vim.fn.getreg('v')
    vim.cmd([[noautocmd sil norm! "vy]])
    local selection = vim.fn.getreg('v')
    vim.fn.setreg('v', saved_reg)
    return tostring(selection)
  end

  return tostring(vim.fn.expand('<cword>'))
end

---@param builtin_name "find_files"|"live_grep"|"grep_string"
---@param opts? table
local function fallback_builtin(builtin_name, opts)
  return require('telescope.builtin')[builtin_name](opts)
end

---@param opts? table
---@return table
function M.file_search_request(opts)
  return {
    cwd = M.picker_cwd(opts),
    max_results = (opts and opts.max_results) or DEFAULT_FILE_PAGE_SIZE,
    mode = 'files',
    wait_for_index_ms = DEFAULT_WAIT_FOR_INDEX_MS,
  }
end

---@param mode "plain"|"regex"
---@param opts? table
---@return table
function M.content_search_request(mode, opts)
  return {
    cwd = M.picker_cwd(opts),
    mode = mode,
    page_size = (opts and opts.page_size) or DEFAULT_GREP_PAGE_SIZE,
    wait_for_index_ms = DEFAULT_WAIT_FOR_INDEX_MS,
  }
end

---@param fff table
---@param query string
---@param opts? table
---@return table
function M.run_file_search(fff, query, opts)
  return fff.file_search(query, M.file_search_request(opts))
end

---@param fff table
---@param query string
---@param mode "plain"|"regex"
---@param opts? table
---@return table
function M.run_content_search(fff, query, mode, opts)
  return fff.content_search(query, M.content_search_request(mode, opts))
end

---@param opts? table
function M.find_files_unsupported(opts)
  return has_any_option(opts, {
    'file_entry_encoding',
    'find_command',
    'follow',
    'hidden',
    'no_ignore',
    'no_ignore_parent',
    'search_dirs',
    'search_file',
  })
end

---@param opts? table
function M.live_grep_unsupported(opts)
  return has_any_option(opts, {
    'additional_args',
    'disable_coordinates',
    'glob_pattern',
    'grep_open_files',
    'only_sort_text',
    'search_dirs',
    'type_filter',
  })
end

---@param opts? table
function M.grep_string_unsupported(opts)
  return has_any_option(opts, {
    'grep_open_files',
    'search_dirs',
    'word_match',
  })
end

---@param prompt string
---@param search fun(query: string): table
---@param map_results fun(result: table): string[]
---@return string[]
function M.search_lines(prompt, search, map_results)
  local ok, result = pcall(search, prompt)
  if not ok or type(result) ~= 'table' then return {} end
  return map_results(result)
end

---@param fff table
---@param opts? table
---@return fun(prompt: string): string[]
function M.find_files_searcher(fff, opts)
  return function(prompt)
    return M.search_lines(
      prompt or '',
      function(query) return M.run_file_search(fff, query, opts) end,
      M._file_search_lines
    )
  end
end

---@param fff table
---@param opts? table
---@return fun(prompt: string): string[]
function M.live_grep_searcher(fff, opts)
  return function(prompt)
    if not prompt or prompt == '' then return {} end
    return M.search_lines(
      prompt,
      function(query) return M.run_content_search(fff, query, 'regex', opts) end,
      M._grep_result_lines
    )
  end
end

---@param fff table
---@param query string
---@param opts? table
---@return string[]
function M.grep_string_lines(fff, query, opts)
  local mode = M._grep_mode_for_grep_string(opts)
  local result = M.run_content_search(fff, query, mode, opts)
  return M._grep_result_lines(result)
end

---@param prompt_title string
---@param opts? table
---@param entry_maker fun(value: any): table
---@param finder_fn fun(prompt: string): string[]
---@param previewer any
---@param push_cursor_on_edit? boolean
local function open_dynamic_picker(
  prompt_title,
  opts,
  entry_maker,
  finder_fn,
  previewer,
  push_cursor_on_edit
)
  local telescope = M._require_telescope()
  local picker_opts = M.telescope_picker_opts(opts)

  telescope.pickers
    .new(picker_opts, {
      prompt_title = prompt_title,
      __locations_input = true,
      finder = telescope.finders.new_dynamic({
        entry_maker = entry_maker,
        fn = finder_fn,
      }),
      previewer = previewer,
      push_cursor_on_edit = push_cursor_on_edit,
      -- Preserve FFF's own ranking for dynamic result sets while still using
      -- Telescope for filtering highlights and picker UI.
      sorter = telescope.sorters.highlighter_only(picker_opts),
    })
    :find()
end

---@param title string
---@param opts? table
---@param results string[]
---@param entry_maker fun(value: any): table
local function open_static_picker(title, opts, results, entry_maker)
  local telescope = M._require_telescope()
  local picker_opts = M.telescope_picker_opts(opts)

  telescope.pickers
    .new(picker_opts, {
      prompt_title = title,
      finder = telescope.finders.new_table({
        entry_maker = entry_maker,
        results = results,
      }),
      previewer = telescope.conf.grep_previewer(picker_opts),
      push_cursor_on_edit = true,
      -- Keep Telescope's generic sorter for this static result set so in-picker
      -- refinement stays strong. With an empty prompt, the incoming FFF order is preserved.
      sorter = telescope.conf.generic_sorter(picker_opts),
    })
    :find()
end

---@param opts? table
function M.find_files(opts)
  if M.find_files_unsupported(opts) then return fallback_builtin('find_files', opts) end

  local fff = M.resolve_fff_backend(opts)
  if fff == nil then return fallback_builtin('find_files', opts) end

  local telescope = M._require_telescope()
  local picker_opts = M.telescope_picker_opts(opts)
  local entry_maker = telescope.make_entry.gen_from_file(picker_opts)

  return open_dynamic_picker(
    'Find Files',
    picker_opts,
    entry_maker,
    M.find_files_searcher(fff, picker_opts),
    telescope.conf.grep_previewer(picker_opts)
  )
end

---@param opts? table
function M.live_grep(opts)
  if M.live_grep_unsupported(opts) then return fallback_builtin('live_grep', opts) end

  local fff = M.resolve_fff_backend(opts)
  if fff == nil then return fallback_builtin('live_grep', opts) end

  local telescope = M._require_telescope()
  local picker_opts = M.telescope_picker_opts(opts)
  local entry_maker = telescope.make_entry.gen_from_vimgrep(picker_opts)

  return open_dynamic_picker(
    'Live Grep',
    picker_opts,
    entry_maker,
    M.live_grep_searcher(fff, picker_opts),
    telescope.conf.grep_previewer(picker_opts),
    true
  )
end

---@param opts? table
function M.grep_string(opts)
  if M.grep_string_unsupported(opts) then return fallback_builtin('grep_string', opts) end

  local query = M._grep_string_query(opts)
  if query == '' then return fallback_builtin('grep_string', opts) end

  local fff = M.resolve_fff_backend(opts)
  if fff == nil then return fallback_builtin('grep_string', opts) end

  local search_ok, lines = pcall(M.grep_string_lines, fff, query, opts)
  if not search_ok or type(lines) ~= 'table' then return fallback_builtin('grep_string', opts) end

  local telescope = M._require_telescope()
  local picker_opts = M.telescope_picker_opts(opts)
  local entry_maker = telescope.make_entry.gen_from_vimgrep(picker_opts)

  return open_static_picker(
    'Find Word (' .. query:gsub('\n', '\\n') .. ')',
    picker_opts,
    lines,
    entry_maker
  )
end

return M
