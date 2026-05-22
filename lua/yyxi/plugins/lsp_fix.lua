local M = {}

function M.setup()
  local fix = require('lsp-fix')

  fix.setup({
    json5 = {
      order = {
        'eslint',
      },
    },
    jsonc = {
      order = {
        'eslint',
      },
    },
    toml = {
      order = {
        'taplo',
        'eslint',
      },
    },
    json = {
      order = {
        'eslint',
      },
    },
    yaml = {
      order = {
        'eslint',
      },
    },
    typescript = {
      order = {
        'ts_ls',
        'vtsls',
        'eslint',
      },
    },
    dockerfile = {
      order = {
        'dockerls',
      },
    },
    python = {
      order = {
        'ty',
        'pyright',
        'ruff',
      },
    },
    vue = {
      order = {
        'volar',
        'eslint',
      },
    },
    -- css = {
    --   order = { 'stylelint_lsp' },
    --   tab_width = function()
    --     return vim.opt.shiftwidth:get()
    --   end,
    -- }
  })
end

return M
