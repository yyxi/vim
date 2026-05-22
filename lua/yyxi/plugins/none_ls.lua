local M = {}

---@class yyxi.plugins.none_ls.Context
---@field is_installed fun(binary: string): boolean

---@param context yyxi.plugins.none_ls.Context
function M.setup(context)
  local is_installed = context.is_installed

  local null_ls = require('null-ls')
  null_ls.setup({
    sources = {
      -- https://github.com/nvimtools/none-ls.nvim/blob/main/doc/BUILTINS.md
      null_ls.builtins.diagnostics.actionlint.with({
        condition = function() return is_installed('actionlint') end,
      }),
      null_ls.builtins.diagnostics.fish.with({
        condition = function() return is_installed('fish') end,
      }),
      null_ls.builtins.diagnostics.hadolint.with({
        condition = function() return is_installed('hadolint') end,
      }),
    },
  })
end

return M
