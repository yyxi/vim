local lsp = require('lsp-zero').preset({
  float_border = 'rounded',
  call_servers = 'local',
  configure_diagnostics = false,
  setup_servers_on_start = true,
  set_lsp_keymaps = false,
  manage_nvim_cmp = {
    set_sources = 'recommended',
    set_basic_mappings = false,
    set_extra_mappings = false,
    use_luasnip = true,
    set_format = true,
    documentation_window = true,
  },
})

lsp.set_sign_icons({
  error = '◆',
  warn = '◇',
  hint = '•',
  info = '∙',
})

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
  vue = {
    order = { 'volar', 'eslint' },
    tab_width = function()
      return vim.opt.shiftwidth:get()
    end,
  },
  -- css = {
  --   order = { 'stylelint_lsp' },
  --   tab_width = function()
  --     return vim.opt.shiftwidth:get()
  --   end,
  -- }
})

local has_words_before = function()
  if vim.api.nvim_buf_get_option(0, 'buftype') == 'prompt' then
    return false
  end
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return col ~= 0
    and vim.api
        .nvim_buf_get_lines(0, line - 1, line, true)[1]
        :sub(col, col)
        :match('%s')
      == nil
end

lsp.setup_nvim_cmp({
  documentation = true,
  preselect = cmp.PreselectMode.None,
  completion = {
    completeopt = 'menu,menuone,noinsert,noselect',
  },
  sorting = {
    comparators = {
      cmp.config.compare.offset,
      cmp.config.compare.exact,
      cmp.config.compare.score,
      cmp.config.compare.recently_used,
      cmp.config.compare.kind,
      cmp.config.compare.sort_text,
      -- cmp.config.compare.length,
      -- cmp.config.compare.order,
    },
  },
  window = {
    completion = cmp.config.window.bordered(),
    documentation = cmp.config.window.bordered(),
  },
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
    ['<C-e>'] = cmp.mapping(function( --[[ fallback ]])
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
    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item({ behavior = cmp.SelectBehavior.Insert })
      else
        fallback()
      end
    end, { 'i', 's' }),
  },
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

lsp.configure('stylelint_lsp', {
  filetypes = {
    'css',
    'less',
    'scss',
    'sugarss',
    'vue',
    'wxss',
  },
  format = {
    function(bufnr, client)
      local params = {
        command = 'stylelint.applyAutoFixes',
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

lsp.configure('yamlls', {
  settings = {
    yaml = {
      schemas = vim.list_extend(
        {
          [vim.fn.expand('~/.vim/lua/user/empty_schema.json')] = 'contents.yaml',
        },
        require('schemastore').yaml.schemas({
          ignore = {
            'IMG Catapult PSP',
          },
        })
      ),
      validate = { enable = true },
    },
  },
})

lsp.configure('jsonls', {
  settings = {
    json = {
      schemas = require('schemastore').json.schemas(),
      validate = { enable = true },
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

  vim.api.nvim_buf_set_keymap(
    bufnr,
    'n',
    'xD',
    '<cmd>lua vim.lsp.buf.declaration()<cr>',
    opts
  )

  vim.api.nvim_buf_set_keymap(
    bufnr,
    'n',
    'xd',
    '<cmd>Telescope lsp_definitions<cr>', --[[ '<cmd>lua vim.lsp.buf.definition()<cr>' ]]
    opts
  )

  vim.api.nvim_buf_set_keymap(
    bufnr,
    'n',
    'xi',
    '<cmd>Telescope lsp_implementations<cr><cr>', --[[ '<cmd>lua vim.lsp.buf.implementation()<cr>' ]]
    opts
  )

  vim.api.nvim_buf_set_keymap(
    bufnr,
    'n',
    'xt',
    '<cmd>Telescope lsp_type_definitions<cr>', --[[ '<cmd>lua vim.lsp.buf.type_definition()<cr>' ]]
    opts
  )

  vim.api.nvim_buf_set_keymap(
    bufnr,
    'n',
    'xR',
    '<cmd>Telescope lsp_references<cr>', --[[ '<cmd>lua vim.lsp.buf.references()<cr>' ]]
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
    css = {
      require('formatter.filetypes.css').prettier,
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
      require('formatter.filetypes.yaml').prettier,
      require('formatter.filetypes.yaml').yaml,
    },
    ['yaml.ansible'] = {
      require('formatter.filetypes.yaml').prettier,
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

lsp.ensure_installed({
  'lua_ls',
})
lsp.nvim_workspace()
lsp.setup()

vim.diagnostic.config({
  float = {
    focusable = true,
    -- style = 'minimal',
    border = 'rounded',
    source = 'always',
    header = '',
    prefix = '',
    -- format = function(diagnostic)
    --   return string.format('%s: %s', diagnostic.source, diagnostic.message)
    -- end,
  },
  underline = {
    -- Do not underline text when severity is low (INFO or HINT).
    severity = { min = vim.diagnostic.severity.WARN },
  },
  virtual_text = false,
  signs = false,
  update_in_insert = false,
  severity_sort = false,
})

vim.lsp.set_log_level("WARN")

-- local lsp_conficts, _ = pcall(vim.api.nvim_get_autocmds, { group = "LspAttach_conflicts" })
-- if not lsp_conficts then
-- 	vim.api.nvim_create_augroup("LspAttach_conflicts", {})
-- end
-- vim.api.nvim_create_autocmd("LspAttach", {
-- 	group = "LspAttach_conflicts",
-- 	desc = "prevent tsserver and volar competing",
-- 	callback = function(args)
-- 		if not (args.data and args.data.client_id) then
-- 			return
-- 		end
-- 		local active_clients = vim.lsp.get_active_clients()
-- 		local client = vim.lsp.get_client_by_id(args.data.client_id)
-- 		-- prevent tsserver and volar competing
--                 -- if client.name == "volar" or require("lspconfig").util.root_pattern("nuxt.config.ts")(vim.fn.getcwd()) then
--                 -- OR
-- 		if client.name == "volar" then
-- 			for _, client_ in pairs(active_clients) do
-- 				-- stop tsserver if volar is already active
-- 				if client_.name == "tsserver" then
-- 					client_.stop()
-- 				end
-- 			end
-- 		elseif client.name == "tsserver" then
-- 			for _, client_ in pairs(active_clients) do
-- 				-- prevent tsserver from starting if volar is already active
-- 				if client_.name == "volar" then
-- 					client.stop()
-- 				end
-- 			end
-- 		end
-- 	end,
-- })
