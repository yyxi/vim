local lsp = require('lsp-zero')
-- local cmp = require('cmp')
local lsp_format = require('lsp-format')
local formatter = require('formatter')
local copyf = require('formatter.util').copyf

lsp_format.setup({
  typescript = {
    order = { 'tsserver', 'eslint' },
    tab_width = function()
      return vim.opt.shiftwidth:get()
    end,
  },
})

lsp.preset('recommended')

lsp.set_preferences({
  suggest_lsp_servers = true,
  setup_servers_on_start = true,
  set_lsp_keymaps = true,
  configure_diagnostics = true,
  cmp_capabilities = true,
  manage_nvim_cmp = true,
  call_servers = 'local',
  sign_icons = {
    error = '◆',
    warn = '◇',
    hint = '•',
    info = '∙',
  },
})

vim.diagnostic.config({
  virtual_text = true,
  signs = false,
  update_in_insert = false,
  underline = true,
  severity_sort = false,
  float = true,
})

lsp.setup_nvim_cmp({
  documentation = true,
})

lsp.ensure_installed({
  'lua_ls',
})

lsp.configure('tsserver', {
  format = {
    function(bufnr, client)
      local params = {
        command = '_typescript.organizeImports',
        arguments = { vim.api.nvim_buf_get_name(bufnr) },
      }

      client.request_sync('workspace/executeCommand', params, 3000, bufnr)
    end,
  },
})

lsp.configure('eslint', {
  format = {
    function(bufnr, client)
      local params = {
        command = 'eslint.applyAllFixes',
        arguments = {
          {
            uri = vim.uri_from_bufnr(bufnr),
            version = vim.lsp.util.buf_versions[bufnr],
          },
        },
      }

      client.request_sync('workspace/executeCommand', params, 3000, bufnr)
    end,
  },
})

lsp.configure('jsonls', {
  settings = {
    json = {
      -- Schemas https://www.schemastore.org
      schemas = {
        {
          fileMatch = { 'package.json' },
          url = 'https://json.schemastore.org/package.json',
        },
        {
          fileMatch = { 'tsconfig*.json' },
          url = 'https://json.schemastore.org/tsconfig.json',
        },
        {
          fileMatch = {
            '.prettierrc',
            '.prettierrc.json',
            'prettier.config.json',
          },
          url = 'https://json.schemastore.org/prettierrc.json',
        },
        {
          fileMatch = { '.eslintrc', '.eslintrc.json' },
          url = 'https://json.schemastore.org/eslintrc.json',
        },
      },
    },
  },
})

lsp.on_attach(function(client)
  lsp_format.on_attach(client)
end)

lsp.nvim_workspace()
lsp.setup()

formatter.setup({
  -- Enable or disable logging
  logging = true,
  -- Set the log level
  log_level = vim.log.levels.WARN,
  -- All formatter configurations are opt-in
  filetype = {
    javascript = {
      require('formatter.filetypes.javascript').prettier,
    },
    typescript = {
      require('formatter.filetypes.typescript').prettier,
    },
    vue = {
      copyf(require('formatter.defaults.prettier')),
    },
    sh = {
      require('formatter.filetypes.sh').shfmt,
    },
    lua = {
      require('formatter.filetypes.lua').stylua,
    },
    yaml = {
      require('formatter.filetypes.yaml').yaml,
    },
    ["yaml.ansible"] = {
      require('formatter.filetypes.yaml').yaml,
    },
    json = {
      require('formatter.filetypes.json').prettier,
    },
    ['*'] = {
      require('formatter.filetypes.any').remove_trailing_whitespace,
    },
  },
})

vim.api.nvim_set_keymap(
  'n',
  'xf',
  "<cmd>lua require('lsp-format').format()<cr><cmd>FormatLock<cr>",
  { noremap = true, silent = true }
)

-- map('n', 'xf', 'gf')
-- vim.bind('x', 'f', '<cmd>lua LspFormat<cr>')
-- bind('n', 'Q', function() print('Hello') end, {buffer = bufnr, desc = 'Say hello'})
