local M = {}

function M.setup()
  ---@type conform.setupOpts
  local opts = {
    formatters_by_ft = {
      javascript = { 'prettier' },
      json = { 'prettier' },
      json5 = { 'prettier' },
      jsonc = { 'prettier' },
      -- lua = { 'stylua' },
      tex = { 'latexindent' },
      markdown = { 'prettier' },
      sh = { 'shfmt' },
      typescript = { 'prettier' },
      typescriptreact = { 'prettier' },
      css = { 'prettier' },
      vue = { 'prettier' },
      yaml = { 'prettier' },
    },
    formatters = {
      shfmt = {
        prepend_args = { '-i', '2' },
      },
    },
  }

  require('conform').setup(opts)
end

return M
