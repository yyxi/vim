local M = {}

local transient_ui_filetypes = {
  'cmp_menu',
  'flash_prompt',
  'noice',
  'notify',
}

local picker_filetypes = {
  'lazy',
  'TelescopePrompt',
}

local non_editing_buftypes = {
  'help',
  'nofile',
  'nowrite',
  'quickfix',
  'terminal',
  'prompt',
}

---@generic T
---@param values T[]
---@return T[]
local function list(values) return vim.deepcopy(values) end

---@generic T
---@param ... T[]
---@return T[]
local function concat(...)
  local values = {}
  for _, source in ipairs({ ... }) do
    vim.list_extend(values, source)
  end
  return values
end

---@return string[]
function M.transient_ui_filetypes() return list(transient_ui_filetypes) end

---@return string[]
function M.picker_filetypes() return list(picker_filetypes) end

---@return string[]
function M.non_editing_buftypes() return list(non_editing_buftypes) end

---@return string[]
function M.autopairs_disabled_filetypes() return concat(picker_filetypes, { 'vim' }) end

---@return string[]
function M.cybu_excluded_filetypes()
  return concat(transient_ui_filetypes, {
    'fugitive',
    'neo-tree',
    'qf',
  })
end

---@return string[]
function M.which_key_disabled_filetypes() return M.picker_filetypes() end

---@return table<string, table>
function M.lualine_disabled_filetypes()
  return {
    statusline = {},
    winbar = {},
    help = {},
  }
end

---@return (string|fun(win: integer): boolean)[]
function M.flash_search_exclusions()
  local values = M.transient_ui_filetypes()
  table.insert(values, function(win) return not vim.api.nvim_win_get_config(win).focusable end)
  return values
end

return M
