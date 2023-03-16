local lsp = require('lsp-zero')
local lsp_format = require('lsp-format')
local formatter = require('formatter')
local copyf = require('formatter.util').copyf
local cmp = require('cmp')

lsp_format.setup({
  typescript = {
    order = { 'tsserver', 'eslint' },
    tab_width = function()
      return vim.opt.shiftwidth:get()
    end,
  },
})

lsp.preset({
  name = 'minimal',
  suggest_lsp_servers = true,
  setup_servers_on_start = true,
  set_lsp_keymaps = false,
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
  -- float = {
  --   focusable = false,
  --   style = 'minimal',
  --   border = 'rounded',
  --   source = 'always',
  --   header = '',
  --   prefix = '',
  -- },
  virtual_text = true,
  signs = false,
  update_in_insert = false,
  underline = true,
  severity_sort = false,
  float = true,
})

lsp.setup_nvim_cmp({
  documentation = true,
  mapping = {
    ['<CR>'] = cmp.mapping.confirm({ select = false }),
    ['<C-y>'] = cmp.mapping.confirm({ select = false }),

    -- navigate items on the list
    ['<Up>'] = cmp.mapping.select_prev_item({
      behavior = cmp.SelectBehavior.Insert,
    }),
    ['<Down>'] = cmp.mapping.select_next_item({
      behavior = cmp.SelectBehavior.Insert,
    }),
    ['<C-p>'] = cmp.mapping.select_prev_item({
      behavior = cmp.SelectBehavior.Insert,
    }),
    ['<C-n>'] = cmp.mapping.select_next_item({
      behavior = cmp.SelectBehavior.Insert,
    }),

    -- scroll up and down in the completion documentation
    ['<C-f>'] = cmp.mapping.scroll_docs(5),
    ['<C-u>'] = cmp.mapping.scroll_docs(-5),

    -- toggle completion
    ['<C-e>'] = cmp.mapping(function(--[[ fallback ]])
      if cmp.visible() then
        cmp.abort()
      else
        cmp.complete()
      end
    end),

    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item({ behavior = cmp.SelectBehavior.Insert })
      elseif has_words_before() then
        cmp.complete()
      else
        fallback()
      end
    end, { 'i', 's' }),

    ['<S-Tab>'] = cmp.mapping(function()
      if cmp.visible() then
        cmp.select_prev_item({ behavior = cmp.SelectBehavior.Insert })
      end
    end, { 'i', 's' }),
  },
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

lsp.on_attach(function(client, bufnr)
  local opts = { noremap = true, silent = true }

  vim.api.nvim_buf_set_keymap(
    bufnr,
    'n',
    '<C-k>',
    '<cmd>lua vim.lsp.buf.signature_help()<cr>',
    opts
  )
  vim.api.nvim_buf_set_keymap(
    bufnr,
    'n',
    'K',
    '<cmd>lua vim.lsp.buf.hover()<cr>',
    opts
  )
  -- vim.api.nvim_buf_set_keymap(bufnr, 'n', 'xf', 'gf', opts)
  vim.api.nvim_buf_set_keymap(
    bufnr,
    'n',
    'xd',
    '<cmd>lua vim.lsp.buf.definition()<cr>',
    opts
  )
  -- vim.api.nvim_buf_set_keymap(bufnr, 'n', 'xd', '<cmd>Telescope lsp_definitions<cr>', opts)
  vim.api.nvim_buf_set_keymap(
    bufnr,
    'n',
    'xD',
    '<cmd>lua vim.lsp.buf.declaration()<cr>',
    opts
  )
  -- vim.api.nvim_buf_set_keymap(bufnr, 'n', 'xi', '<cmd>lua vim.lsp.buf.implementation()<cr>', opts)
  vim.api.nvim_buf_set_keymap(
    bufnr,
    'n',
    'xi',
    '<cmd>Telescope lsp_implementations<cr><cr>',
    opts
  )
  -- vim.api.nvim_buf_set_keymap(bufnr, 'n', 'xt', '<cmd>lua vim.lsp.buf.type_definition()<cr>', opts)
  vim.api.nvim_buf_set_keymap(
    bufnr,
    'n',
    'xt',
    '<cmd>Telescope lsp_type_definitions<cr>',
    opts
  )
  -- vim.api.nvim_buf_set_keymap(bufnr, 'n', 'xR', '<cmd>lua vim.lsp.buf.references()<cr>', opts)
  vim.api.nvim_buf_set_keymap(
    bufnr,
    'n',
    'xR',
    '<cmd>Telescope lsp_references<cr>',
    opts
  )
  vim.api.nvim_buf_set_keymap(
    bufnr,
    'n',
    'xr',
    '<cmd>lua vim.lsp.buf.rename()<cr>',
    opts
  )
  vim.api.nvim_buf_set_keymap(
    bufnr,
    'n',
    'xa',
    '<cmd>lua vim.lsp.buf.code_action()<cr>',
    opts
  )
  vim.api.nvim_buf_set_keymap(
    bufnr,
    'x',
    'xa',
    '<cmd>lua vim.lsp.buf.code_action()<cr>',
    opts
  )

  vim.api.nvim_buf_set_keymap(
    bufnr,
    'n',
    '<C-Up>',
    '<cmd>lua vim.diagnostic.goto_prev()<cr>',
    opts
  )
  vim.api.nvim_buf_set_keymap(
    bufnr,
    'n',
    '<C-Down>',
    '<cmd>lua vim.diagnostic.goto_next()<cr>',
    opts
  )

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
    ['yaml.ansible'] = {
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
