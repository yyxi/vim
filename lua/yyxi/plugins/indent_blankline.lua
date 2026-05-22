local M = {}

function M.setup()
  require('ibl').setup({
    indent = {
      smart_indent_cap = true,
      highlight = { 'IndentBlanklineChar' },
      char = {
        '╎',
        '╏',
        '┆',
        '┇',
        '┊',
        '┋',
      },
    },
    exclude = { filetypes = {} },
    whitespace = {
      --highlight = highlight,
      remove_blankline_trail = false,
    },
    scope = {
      highlight = { 'IndentBlanklineCharScope' },
      enabled = true,
      show_start = false,
      show_end = false,
      show_exact_scope = false,
    },
  })

  local hooks = require('ibl.hooks')
  hooks.register(hooks.type.WHITESPACE, hooks.builtin.hide_first_space_indent_level)
  hooks.register(hooks.type.WHITESPACE, hooks.builtin.hide_first_tab_indent_level)
end

return M
