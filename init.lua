-- 'wincent/terminus'
-- 'ojroques/vim-oscyank'

vim.cmd([[
if !empty(&viminfo)
  set viminfo^=!
endif

filetype plugin on
filetype plugin indent on
syntax off
au FileType help,qf setl nowrap nofen nospell nocul nolist

map <c-j> <c-w>j
map <c-k> <c-w>k
map <c-l> <c-w>l
map <c-h> <c-w>h
" nn ; :
cm WQ wq
cm wQ wq
cm Tabe tabe
cm w!! w !sudo tee % >/dev/null

" noremap 0 ^
" noremap ^ 0

nnoremap <expr> n (v:searchforward ? 'n' : 'N')
nnoremap <expr> N (v:searchforward ? 'N' : 'n')

nnoremap <Up> n
nnoremap <Down> N
nnoremap <leader><leader> :b#<CR>

" autocmd VimEnter *
"   \   delc Format
"   \ | delc FormatWrite
"   \ | delc FormatWriteLock
"   \ | delc LspZeroFormat
]])

if vim.loader then
  vim.loader.enable()
end

-- vim.o.wildmode = 'list:longest,full'
-- vim.o.guicursor = 'a:blinkon0'
-- vim.o.mouse = 'nvi'
-- vim.o.complete = ''

vim.g.loaded_netrw = true
vim.g.loaded_netrwPlugin = true
vim.o.autoindent = true
vim.o.autoread = true
vim.o.background = 'dark'
vim.o.backspace = 'indent,eol,start'
vim.o.backup = true
vim.o.backupcopy = 'yes'
vim.o.backupdir = vim.fn.expand('~/.vim/tmp/backup')
vim.o.clipboard = 'unnamedplus'
vim.o.cmdheight = 2
vim.o.colorcolumn = ''
vim.o.compatible = false
vim.o.cursorline = false
vim.o.directory = vim.fn.expand('~/.vim/tmp/sessions')
vim.o.display = 'lastline,truncate'
vim.o.encoding = 'utf-8'
vim.o.errorbells = false
vim.o.expandtab = true
vim.o.fileencoding = 'utf-8'
vim.o.foldenable = false
vim.o.formatoptions = 'jcroqln'
vim.o.hidden = true
vim.o.history = 5000
vim.o.hlsearch = true
vim.o.ignorecase = true
vim.o.inccommand = 'split'
vim.o.incsearch = true
vim.o.joinspaces = false
vim.o.langremap = false
vim.o.laststatus = 3
vim.o.lazyredraw = true
vim.o.linebreak = true
vim.o.list = false
vim.o.listchars = 'tab:¨¨,eol:¬,trail:·'
vim.o.matchtime = 2
vim.o.mouse = 'a'
vim.o.nrformats = 'bin,hex'
vim.o.number = false
vim.o.numberwidth = 6
vim.o.pumblend = 10
vim.o.pumheight = 20
vim.o.relativenumber = false
vim.o.ruler = false
vim.o.scrolljump = 5
vim.o.scrolloff = 1
vim.o.scrolloff = 5
vim.o.secure = true
vim.o.shiftwidth = 2
vim.o.shortmess = 'AIOTWacfilmnortx'
vim.o.showbreak = '↳ '
vim.o.showmode = false
vim.o.sidescroll = 1
vim.o.sidescrolloff = 2
vim.o.signcolumn = 'no'
vim.o.smartcase = true
vim.o.smartindent = true
vim.o.smarttab = true
vim.o.softtabstop = 2
vim.o.spell = false
vim.o.splitbelow = true
vim.o.splitright = true
vim.o.startofline = false
vim.o.swapfile = false
vim.o.tabpagemax = 50
vim.o.tabstop = 2
vim.o.termguicolors = true
vim.o.timeout = true
vim.o.timeoutlen = 300
vim.o.undodir = vim.fn.expand('~/.vim/tmp/undo')
vim.o.undofile = true
vim.o.virtualedit = 'block'
vim.o.virtualedit = 'onemore'
vim.o.visualbell = false
vim.o.whichwrap = '<,>,h,l'
vim.o.wildignore =
  '*/.git/*,*/.hg/*,*/.svn/*,*.aux,*.out,*.toc,*.jpg,*.bmp,*.gif,*.luac,*.o,*.obj,*.exe,*.dll,*.manifest,*.spl,*.py[co]'
vim.o.wildmenu = true
vim.o.wildmode = 'longest:full,full'
vim.o.winblend = 10
vim.o.wrap = false
vim.o.wrapscan = false

vim.lsp.set_log_level('WARN')

vim.diagnostic.config({
  float = {
    border = 'rounded',
    -- focusable = true,
    -- header = '',
    -- prefix = '',
    -- source = 'always',
    -- style = 'minimal',
    -- format = function(diagnostic)
    --   return string.format('%s: %s', diagnostic.source, diagnostic.message)
    -- end,
  },
  underline = {
    severity = { min = vim.diagnostic.severity.WARN },
  },
  virtual_text = false,
  signs = true,
  update_in_insert = false,
  severity_sort = false,
})

local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    lazypath,
  })
  vim.fn.system({ 'git', '-C', lazypath, 'checkout', 'tags/stable' }) -- last stable release
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = '\\'
vim.opt.rtp:prepend(lazypath)
vim.g.editorconfig = true

vim.lsp.handlers['textDocument/hover'] =
  vim.lsp.with(vim.lsp.handlers.hover, { border = 'rounded' })

vim.lsp.handlers['textDocument/signatureHelp'] =
  vim.lsp.with(vim.lsp.handlers.signature_help, { border = 'rounded' })

vim.filetype.add({
  extension = {
    tfvars = 'terraform',
    tfstate = 'json',
  },
  filename = {
    ['go.sum'] = 'go',
    ['yarn.lock'] = 'yaml',
    ['.ansible-lint'] = 'yaml',
  },
  pattern = {
    ['.*%.js%.map'] = 'json',
    ['.*%.postman_collection'] = 'json',
    ['.*/playbooks/.*%.yaml'] = 'yaml.ansible',
    ['.*/playbooks/.*%.yml'] = 'yaml.ansible',
    ['.*/roles/.*%.yaml'] = 'yaml.ansible',
    ['.*/roles/.*%.yml'] = 'yaml.ansible',
  },
})

require('lazy').setup({
  {
    'wincent/terminus',
    lazy = false,
    priority = 1000,
    init = function()
      vim.g.TerminusCursorShape = 1
      vim.g.TerminusInsertCursorShape = 0
      vim.g.TerminusNormalCursorShape = 1
      vim.g.TerminusReplaceCursorShape = 1
      vim.g.TerminusMouse = 1
      vim.g.TerminusFocusReporting = 1
      vim.g.TerminusBracketedPaste = 1
    end,
  },
  {
    'farmergreg/vim-lastplace',
    lazy = false,
    priority = 1000,
  },
  {
    'echasnovski/mini.base16',
    lazy = false, -- make sure we load this during startup if it is your main colorscheme
    branch = 'stable',
    priority = 1000, -- make sure to load this before all the other start plugins
    config = function()
      require('mini.base16').setup({
        palette = {
          base00 = '#1d2021',
          base01 = '#3c3836',
          base02 = '#504945',
          base03 = '#665c54',
          base04 = '#bdae93',
          base05 = '#d5c4a1',
          base06 = '#ebdbb2',
          base07 = '#fbf1c7',
          base08 = '#fb4934',
          base09 = '#fe8019',
          base0A = '#fabd2f',
          base0B = '#b8bb26',
          base0C = '#8ec07c',
          base0D = '#83a598',
          base0E = '#d3869b',
          base0F = '#d65d0e',
        },
        use_cterm = not vim.o.termguicolors,
        plugins = {
          default = false,
          ['echasnovski/mini.nvim'] = true,
          ['folke/lazy.nvim'] = true,
          ['folke/which-key.nvim'] = true,
          ['hrsh7th/nvim-cmp'] = true,
          ['lukas-reineke/indent-blankline.nvim'] = true,
          ['nvim-lualine/lualine.nvim'] = true,
          ['nvim-telescope/telescope.nvim'] = true,
          ['williamboman/mason.nvim'] = true,
        },
      })

      vim.cmd([[
hi! link @text.todo MiniHipatternsTodo
hi! link NormalFloat Normal
hi! link FloatBorder Normal
hi! link FloatBorder Normal
hi! link NormalFloat Normal

hi! link DiagnosticFloatingError Normal
hi! link DiagnosticFloatingHint Normal
hi! link DiagnosticFloatingInfo Normal
hi! link DiagnosticFloatingWarn Normal
hi! link WinSeparator Normal

hi! link WhichKeySeparator String
hi! link WhichKeyFloat Normal
hi! link WhichKeyBorder Normal
hi! link ZenBg Normal
]])
    end,
  },
  {
    'lukas-reineke/indent-blankline.nvim',
    event = 'VeryLazy',
    dependencies = { 'echasnovski/mini.base16' },
    config = function()
      vim.api.nvim_set_hl(0, 'IndentBlanklineChar', {
        nocombine = true,
        ctermbg = nil,
        ctermfg = 8,
        bg = nil,
        fg = '#332E33',
      })

      vim.api.nvim_set_hl(0, 'IndentBlanklineCharScope', {
        nocombine = true,
        ctermbg = nil,
        ctermfg = 8,
        bold = false,
        bg = nil,
        fg = '#474247',
      })

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
      hooks.register(
        hooks.type.WHITESPACE,
        hooks.builtin.hide_first_space_indent_level
      )
      hooks.register(
        hooks.type.WHITESPACE,
        hooks.builtin.hide_first_tab_indent_level
      )
    end,
  },
  {
    'echasnovski/mini.hipatterns',
    event = 'VeryLazy',
    dependencies = { 'echasnovski/mini.base16' },
    config = function()
      local hipatterns = require('mini.hipatterns')

      hipatterns.setup({
        highlighters = {
          -- Highlight standalone 'FIXME', 'HACK', 'TODO', 'NOTE'
          fixme = {
            pattern = '%f[%w]()FIXME()%f[%W]',
            group = 'MiniHipatternsFixme',
          },
          hack = {
            pattern = '%f[%w]()HACK()%f[%W]',
            group = 'MiniHipatternsHack',
          },
          todo = {
            pattern = '%f[%w]()TODO()%f[%W]',
            group = 'MiniHipatternsTodo',
          },
          note = {
            pattern = '%f[%w]()NOTE()%f[%W]',
            group = 'MiniHipatternsNote',
          },

          -- Highlight hex color strings (`#rrggbb`) using that color
          hex_color = hipatterns.gen_highlighter.hex_color(),
        },
      })
    end,
  },
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'echasnovski/mini.base16' },
    lazy = false,
    priority = 1000, -- make sure to load this before all the other start plugins
    opts = {
      options = {
        always_divide_middle = true,
        component_separators = '',
        globalstatus = true,
        icons_enabled = false,
        section_separators = '',
        -- theme = 'gruvbox',
        disabled_filetypes = {
          statusline = {},
          winbar = {},
          help = {},
        },
      },
    },
  },
  {
    'VonHeikemen/lsp-zero.nvim',
    branch = 'v3.x',
    lazy = true,
    init = function()
      -- Disable automatic setup, we are doing it manually
      vim.g.lsp_zero_ui_float_border = 0
      vim.g.lsp_zero_ui_signcolumn = 0
      vim.g.lsp_zero_extend_cmp = 0
      vim.g.lsp_zero_extend_lspconfig = 0
    end,
  },
  {
    'williamboman/mason.nvim',
    lazy = false,
    config = true,
  },
  {
    'smjonas/inc-rename.nvim',
    cmd = 'Rename',
    opts = {
      cmd_name = 'Rename',
    },
  },
  {
    'neovim/nvim-lspconfig',
    cmd = { 'LspInfo', 'LspInstall', 'LspStart' },
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = {
      { 'hrsh7th/cmp-nvim-lsp' },
      { 'hrsh7th/cmp-nvim-lua' },
      { 'williamboman/mason.nvim' },
      { 'williamboman/mason-lspconfig.nvim' },
      { 'folke/neodev.nvim' },
      { 'b0o/schemastore.nvim' },
      { 'smjonas/inc-rename.nvim' },
    },
    config = function()
      require('neodev').setup({})
      -- This is where all the LSP shenanigans will live
      local lsp_zero = require('lsp-zero')
      lsp_zero.extend_lspconfig()
      local capabilities = lsp_zero.get_capabilities()

      lsp_zero.set_sign_icons({
        error = '◆',
        warn = '◇',
        hint = '•',
        info = '∙',
      })

      lsp_zero.on_attach(function(client, bufnr)
        local keymap_options = { noremap = true, silent = true }

        vim.api.nvim_buf_set_keymap(
          bufnr,
          'n',
          '<C-k>',
          '<cmd>lua vim.lsp.buf.signature_help()<cr>',
          keymap_options
        )
        vim.api.nvim_buf_set_keymap(
          bufnr,
          'n',
          'K',
          '<cmd>lua vim.lsp.buf.hover()<cr>',
          keymap_options
        )

        vim.api.nvim_buf_set_keymap(
          bufnr,
          'n',
          'xD',
          '<cmd>lua vim.lsp.buf.declaration()<cr>',
          keymap_options
        )

        vim.api.nvim_buf_set_keymap(
          bufnr,
          'n',
          'xd',
          '<cmd>Telescope lsp_definitions<cr>', --[[ '<cmd>lua vim.lsp.buf.definition()<cr>' ]]
          keymap_options
        )

        vim.api.nvim_buf_set_keymap(
          bufnr,
          'n',
          'xi',
          '<cmd>Telescope lsp_implementations<cr><cr>', --[[ '<cmd>lua vim.lsp.buf.implementation()<cr>' ]]
          keymap_options
        )

        vim.api.nvim_buf_set_keymap(
          bufnr,
          'n',
          'xt',
          '<cmd>Telescope lsp_type_definitions<cr>', --[[ '<cmd>lua vim.lsp.buf.type_definition()<cr>' ]]
          keymap_options
        )

        vim.api.nvim_buf_set_keymap(
          bufnr,
          'n',
          'xR',
          '<cmd>Telescope lsp_references<cr>', --[[ '<cmd>lua vim.lsp.buf.references()<cr>' ]]
          keymap_options
        )

        vim.api.nvim_buf_set_keymap(
          bufnr,
          'n',
          'xr',
          ':Rename ',
          -- '<cmd>lua vim.lsp.buf.rename()<cr>',
          keymap_options
        )

        vim.api.nvim_buf_set_keymap(
          bufnr,
          'n',
          'xa',
          '<cmd>lua vim.lsp.buf.code_action()<cr>',
          keymap_options
        )

        vim.api.nvim_buf_set_keymap(
          bufnr,
          'x',
          'xa',
          '<cmd>lua vim.lsp.buf.code_action()<cr>',
          keymap_options
        )

        vim.api.nvim_buf_set_keymap(
          bufnr,
          'n',
          '<C-Up>',
          '<cmd>lua vim.diagnostic.goto_prev()<cr>',
          keymap_options
        )

        vim.api.nvim_buf_set_keymap(
          bufnr,
          'n',
          '<C-Down>',
          '<cmd>lua vim.diagnostic.goto_next()<cr>',
          keymap_options
        )

        require('lsp-fix').on_attach(client, bufnr)
      end)

      require('mason-lspconfig').setup({
        ensure_installed = {},
        handlers = {
          lsp_zero.default_setup,
          lua_ls = function()
            -- (Optional) Configure lua language server for neovim
            local lua_opts = lsp_zero.nvim_lua_ls()
            require('lspconfig').lua_ls.setup(lua_opts)
          end,
          tsserver = function()
            require('lspconfig').tsserver.setup({
              capabilities = capabilities,
              fix = {
                function(bufnr, client)
                  local params = {
                    command = '_typescript.organizeImports',
                    arguments = { vim.api.nvim_buf_get_name(bufnr) },
                  }

                  client.request_sync(
                    'workspace/executeCommand',
                    params,
                    3000,
                    bufnr
                  )
                end,
              },
            })
          end,
          eslint = function()
            require('lspconfig').eslint.setup({
              fix = {
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

                  client.request_sync(
                    'workspace/executeCommand',
                    params,
                    3000,
                    bufnr
                  )
                end,
              },
            })
          end,
          yamlls = function()
            require('lspconfig').yamlls.setup({
              capabilities = capabilities,
              settings = {
                yaml = {
                  schemas = vim.list_extend(
                    {
                      -- TODO: move this
                      [vim.fn.expand('~/.vim/empty-schema.json')] = 'contents.yaml',
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
          end,
          jsonls = function()
            require('lspconfig').jsonls.setup({
              capabilities = capabilities,
              settings = {
                json = {
                  schemas = require('schemastore').json.schemas(),
                  validate = { enable = true },
                },
              },
            })
          end,
        },
      })
    end,
  },
  {
    dir = '~/.vim/local/lsp-fix',
    dependencies = { 'neovim/nvim-lspconfig' },
    keys = {
      {
        'xF',
        function()
          require('lsp-fix').fix()
        end,
        desc = 'Fix',
      },
    },
    config = function()
      local fix = require('lsp-fix')

      fix.setup({
        typescript = {
          order = {
            'tsserver',
            'eslint',
          },
        },
        vue = {
          order = { 'volar', 'eslint' },
        },
        -- css = {
        --   order = { 'stylelint_lsp' },
        --   tab_width = function()
        --     return vim.opt.shiftwidth:get()
        --   end,
        -- }
      })
    end,
  },
  {
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    dependencies = { 'neovim/nvim-lspconfig' },
    keys = {
      {
        'xf',
        function()
          require('conform').format({ async = true, lsp_fallback = true })
        end,
        desc = 'Format',
      },
    },
    config = function()
      require('conform').setup({
        formatters_by_ft = {
          typescript = { { 'prettier' } },
          javascript = { { 'prettier' } },
          markdown = { { 'prettier' } },
          sh = { { 'shfmt' } },
          lua = { { 'stylua' } },
        },
        formatters = {
          shfmt = {
            prepend_args = { '-i', '2' },
          },
        },
      })
    end,
    init = function()
      -- If you want the formatexpr, here is the place to set it
      vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
    end,
  },
  {
    'L3MON4D3/LuaSnip',
    dependencies = { 'rafamadriz/friendly-snippets' },
  },
  {
    'saadparwaiz1/cmp_luasnip',
    dependencies = { 'L3MON4D3/LuaSnip' },
  },
  {
    'hrsh7th/nvim-cmp',
    event = 'InsertEnter',
    dependencies = {
      { 'neovim/nvim-lspconfig' },
      { 'hrsh7th/cmp-buffer' },
      { 'hrsh7th/cmp-path' },
      -- { 'hrsh7th/cmp-cmdline' },
      { 'hrsh7th/cmp-nvim-lsp-document-symbol' },
      { 'L3MON4D3/LuaSnip' },
      { 'saadparwaiz1/cmp_luasnip' },
    },
    config = function()
      -- Here is where you configure the autocompletion settings.
      local lsp_zero = require('lsp-zero')
      lsp_zero.extend_cmp()

      -- And you can configure cmp even more, if you want to.
      local cmp = require('cmp')
      local cmp_action = lsp_zero.cmp_action()

      require('luasnip.loaders.from_vscode').lazy_load()

      cmp.setup({
        preselect = cmp.PreselectMode.None,
        completion = {
          completeopt = 'menu,menuone,noinsert,noselect',
        },
        sources = cmp.config.sources({
          { name = 'nvim_lsp', priority = 16 },
          { name = 'luasnip', priority = 8 },
          { name = 'buffer', priority = 2 },
        }, {
          { name = 'buffer', priority = 2 },
          { name = 'luasnip', priority = 2 },
        }),
        sorting = {
          priority_weight = 10,
          comparators = {
            cmp.config.compare.score,
            cmp.config.compare.exact,
            cmp.config.compare.scopes,
            cmp.config.compare.locality,
            cmp.config.compare.recently_used,
            cmp.config.compare.sort_text,
          },
        },
        window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
        formatting = lsp_zero.cmp_format({ details = true }),
        mapping = cmp.mapping.preset.insert({
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
          ['<Tab>'] = cmp_action.luasnip_supertab(),
          ['<S-Tab>'] = cmp_action.luasnip_shift_supertab(),
        }),
      })

      -- cmp.setup.cmdline({ '/', '?' }, {
      --   mapping = cmp.mapping.preset.cmdline(),
      --   sources = cmp.config.sources({
      --     { name = 'nvim_lsp_document_symbol' },
      --   }, {
      --     { name = 'buffer' },
      --   }),
      -- })
      --
      -- cmp.setup.cmdline(':', {
      --   mapping = cmp.mapping.preset.cmdline(),
      --   sources = cmp.config.sources({
      --     { name = 'path' },
      --   }, {
      --     {
      --       name = 'cmdline',
      --       option = {
      --         ignore_cmds = { 'Man', '!' },
      --       },
      --     },
      --   }),
      -- })
    end,
  },
  {
    'Wansmer/treesj',
    keys = {
      { 'J', '<cmd>TSJToggle<cr>', desc = 'Join Toggle' },
    },
    opts = { use_default_keymaps = false, max_join_length = 150 },
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
  },
  {
    'nvim-treesitter/nvim-treesitter',
    event = { 'BufReadPre', 'BufNewFile' },
    build = ':TSUpdate',
    config = function()
      require('nvim-treesitter.configs').setup({
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },
        indent = {
          enable = true,
        },
        matchup = {
          enable = true,
        },
        autotag = {
          enable = true,
        },
        playground = {
          enable = true,
        },
        incremental_selection = {
          enable = false,
          keymaps = {
            init_selection = 'gnn',
            node_incremental = 'grn',
            scope_incremental = 'grc',
            node_decremental = 'grm',
          },
        },
        textobjects = {
          move = {
            enable = true,
            set_jumps = true,
            goto_next_start = {
              [']m'] = '@function.outer',
              [']]'] = '@class.outer',
            },
            goto_next_end = {
              [']M'] = '@function.outer',
              [']['] = '@class.outer',
            },
            goto_previous_start = {
              ['[m'] = '@function.outer',
              ['[['] = '@class.outer',
            },
            goto_previous_end = {
              ['[M'] = '@function.outer',
              ['[]'] = '@class.outer',
            },
          },
          select = {
            enable = true,
            lookahead = true,

            keymaps = {
              ['af'] = '@function.outer',
              ['if'] = '@function.inner',
              ['aC'] = '@class.outer',
              ['iC'] = '@class.inner',
              ['ac'] = '@conditional.outer',
              ['ic'] = '@conditional.inner',
              ['ae'] = '@block.outer',
              ['ie'] = '@block.inner',
              ['al'] = '@loop.outer',
              ['il'] = '@loop.inner',
              ['is'] = '@statement.inner',
              ['as'] = '@statement.outer',
              ['ad'] = '@comment.outer',
              ['am'] = '@call.outer',
              ['im'] = '@call.inner',
            },
          },
        },
        ensure_installed = {
          'bash',
          'bibtex',
          'cmake',
          'comment',
          'css',
          'dockerfile',
          'dot',
          'eex',
          'elixir',
          'erlang',
          'fish',
          'git_config',
          'git_rebase',
          'gitattributes',
          'gitcommit',
          'gitignore',
          'glsl',
          'go',
          'graphql',
          'hcl',
          'heex',
          'html',
          'http',
          'jq',
          'javascript',
          'jsdoc',
          'sql',
          'json',
          'json5',
          'jsonc',
          'latex',
          'lua',
          'make',
          'mermaid',
          'markdown',
          'perl',
          'proto',
          'prisma',
          'python',
          'r',
          'rust',
          'terraform',
          'toml',
          'tsx',
          'typescript',
          'vim',
          'vue',
          'wgsl',
          'yaml',
        },
        lsp_interop = {
          enable = true,
        },
      })

      vim.o.foldmethod = 'expr'
      vim.o.foldexpr = 'nvim_treesitter#foldexpr()'
      vim.o.indentexpr = 'nvim_treesitter#indent()'
    end,
  },
  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
  },
  {
    'numToStr/Comment.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = {
      'nvim-treesitter/nvim-treesitter-textobjects',
      'JoosepAlviste/nvim-ts-context-commentstring',
    },
    config = function()
      require('Comment').setup({
        pre_hook = require(
          'ts_context_commentstring.integrations.comment_nvim'
        ).create_pre_hook(),
      })
    end,
  },
  {
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    dependencies = { 'hrsh7th/nvim-cmp' },
    config = function()
      require('nvim-autopairs').setup({
        check_ts = true,
        enable_afterquote = true,
        enable_moveright = true,
        enable_check_bracket_line = true,
        disable_filetype = { 'TelescopePrompt', 'vim' },
      })

      local cmp_autopairs = require('nvim-autopairs.completion.cmp')
      local cmp = require('cmp')
      cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done())
    end,
  },
  {
    'kylechui/nvim-surround',
    -- TODO: insert enter?
    event = { 'BufReadPre', 'BufNewFile' },
    version = '*', -- Use for stability; omit to use `main` branch for the latest features
    config = function()
      require('nvim-surround').setup()
    end,
  },
  { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
  {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.5',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-telescope/telescope-fzf-native.nvim',
      'nvim-treesitter/nvim-treesitter',
    },
    cmd = { 'Telescope' },
    keys = {
      { '<leader>f', '<cmd>Telescope find_files<cr>', desc = 'Files' },
      { '<leader>b', '<cmd>Telescope buffers<cr>', desc = 'Buffers' },
      {
        '<leader>s',
        '<cmd>Telescope lsp_document_symbols<cr>',
        desc = 'Symbols',
      },
    },
    config = function()
      local telescope = require('telescope')

      telescope.setup({
        defaults = {
          mappings = {},
          winblend = 10,
        },
        pickers = {
          find_files = {
            find_command = {
              'rg',
              '-L',
              '--files',
              '--color',
              'never',
              '--hidden',
              '--glob',
              '!.git',
            },
          },
        },
        -- file_ignore_patterns = { '.git' },
        extensions = {
          fzf = {
            fuzzy = true, -- false will only do exact matching
            override_generic_sorter = true, -- override the generic sorter
            override_file_sorter = true, -- override the file sorter
            case_mode = 'smart_case', -- or "ignore_case" or "respect_case"
          },
        },
      })

      telescope.load_extension('fzf')
    end,
  },
  {
    'gbprod/yanky.nvim',
    event = 'InsertEnter',
    dependencies = { 'nvim-telescope/telescope.nvim' },
    keys = {
      { '<leader>y', '<cmd>Telescope yank_history<cr>', desc = 'Yank History' },
    },
    config = function()
      require('yanky').setup({
        ring = {
          history_length = 100,
          storage = 'shada',
          sync_with_numbered_registers = true,
          cancel_event = 'update',
        },
        picker = {
          select = {
            action = nil, -- nil to use default put action
          },
          telescope = {
            mappings = nil, -- nil to use default mappings
          },
        },
        system_clipboard = {
          sync_with_ring = true,
        },
        highlight = {
          on_put = false,
          on_yank = false,
        },
        preserve_cursor_position = {
          enabled = true,
        },
      })

      -- vim.keymap.set({ 'n', 'x' }, 'p', '<Plug>(YankyPutAfter)')
      -- vim.keymap.set({ 'n', 'x' }, 'P', '<Plug>(YankyPutBefore)')
      -- vim.keymap.set({ 'n', 'x' }, 'gp', '<Plug>(YankyGPutAfter)')
      -- vim.keymap.set({ 'n', 'x' }, 'gP', '<Plug>(YankyGPutBefore)')
      -- vim.keymap.set('n', '<c-n>', '<Plug>(YankyCycleForward)')
      -- vim.keymap.set('n', '<c-p>', '<Plug>(YankyCycleBackward)')
      -- vim.keymap.set({ 'n', 'x' }, 'y', '<Plug>(YankyYank)')

      require('telescope').load_extension('yank_history')
    end,
  },
  {
    'folke/flash.nvim',
    event = 'VeryLazy',
    opts = {
      labels = 'abcdefghijklmnopqrstuvwxyz',
      search = {
        multi_window = true,
        forward = true,
        wrap = true,
        mode = 'exact',
        -- behave like `incsearch`
        incremental = false,
      },
      jump = {
        jumplist = false,
        history = false,
        register = false,
        nohlsearch = false,
        autojump = false,
      },
      label = {
        uppercase = true,
        reuse = 'lowercase', ---@type "lowercase" | "all" | "none"
        rainbow = {
          enabled = true,
          shade = 5,
        },
      },
      highlight = {
        backdrop = true,
        matches = true,
      },
      modes = {
        char = {
          enabled = false,
        },
      },
      prompt = {
        enabled = false,
      },
    },
    keys = {
      {
        '<c-s>',
        mode = { 'c' },
        function()
          require('flash').toggle()
        end,
        desc = 'Toggle Flash Search',
      },
    },
  },
  {
    'jinh0/eyeliner.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      require('eyeliner').setup({
        highlight_on_key = false, -- this must be set to true for dimming to work!
        dim = false,
      })
      vim.api.nvim_set_hl(
        0,
        'EyelinerPrimary',
        { bold = true, underline = true }
      )
      vim.api.nvim_set_hl(0, 'EyelinerSecondary', { bold = true })
    end,
  },
  -- {
  --   'echasnovski/mini.jump2d',
  --   dependencies = { 'echasnovski/mini.base16' },
  --   keys = { '<CR>' },
  --   config = function()
  --     require('mini.jump2d').setup()
  --   end,
  -- },
  {
    'max397574/better-escape.nvim',
    event = 'InsertEnter',
    lazy = false,
    keys = { 'jj' },
    config = function()
      require('better_escape').setup({
        -- timeout = 300,
        mapping = { 'jj' },
        clear_empty_lines = false,
        keys = '<Esc>',
      })
    end,
  },
  { 'christoomey/vim-sort-motion', event = 'InsertEnter' },
  {
    'junegunn/vim-easy-align',
    event = 'InsertEnter',
    keys = {
      {
        'ga',
        '<Plug>(EasyAlign)<cr>',
        desc = 'EasyAlign in visual mode',
        mode = 'x',
      },
      {
        'ga',
        '<Plug>(EasyAlign)<cr>',
        desc = 'EasyAlign in visual mode',
        mode = 'n',
      },
    },
  },
  {
    'folke/which-key.nvim',
    event = 'VeryLazy',
    -- init = function()
    --   vim.o.timeout = true
    --   vim.o.timeoutlen = 300
    -- end,
    opts = {
      plugins = {
        marks = false,
        registers = false,
        spelling = {
          enabled = false,
        },
        presets = {
          operators = true, -- adds help for operators like d, y, ...
          motions = true, -- adds help for motions
          text_objects = true, -- help for text objects triggered after entering an operator
          windows = true, -- default bindings on <c-w>
          nav = true, -- misc bindings to work with windows
          z = false, -- bindings for folds, spelling and others prefixed with z
          g = true, -- bindings for prefixed with g
        },
      },
      -- add operators that will trigger motion and text object completion
      -- to enable all native operators, set the preset / operators plugin above
      operators = { gc = 'Comments' },
      key_labels = {
        -- override the label used to display some keys. It doesn't effect WK in any other way.
        -- For example:
        -- ["<space>"] = "SPC",
        -- ["<cr>"] = "RET",
        -- ["<tab>"] = "TAB",
      },
      motions = {
        count = true,
      },
      icons = {
        breadcrumb = '»', -- symbol used in the command line area that shows your active key combo
        separator = '➜', -- symbol used between a key and it's label
        group = '+', -- symbol prepended to a group
      },
      popup_mappings = {
        scroll_down = '<c-d>', -- binding to scroll down inside the popup
        scroll_up = '<c-u>', -- binding to scroll up inside the popup
      },
      window = {
        border = 'single', -- none, single, double, shadow
        position = 'top', -- bottom, top
        margin = { 1, 0, 1, 0 }, -- extra window margin [top, right, bottom, left]. When between 0 and 1, will be treated as a percentage of the screen size.
        padding = { 1, 2, 1, 2 }, -- extra window padding [top, right, bottom, left]
        winblend = 10, -- value between 0-100 0 for fully opaque and 100 for fully transparent
        zindex = 1000, -- positive value to position WhichKey above other floating windows.
      },
      layout = {
        height = { min = 4, max = 25 }, -- min and max height of the columns
        width = { min = 20, max = 50 }, -- min and max width of the columns
        spacing = 3, -- spacing between columns
        align = 'left', -- align columns left, center or right
      },
      ignore_missing = false, -- enable this to hide mappings for which you didn't specify a label
      hidden = {
        '<silent>',
        '<cmd>',
        '<Cmd>',
        '<CR>',
        '^:',
        '^ ',
        '^call ',
        '^lua ',
      }, -- hide mapping boilerplate
      show_help = true, -- show a help message in the command line for using WhichKey
      show_keys = true, -- show the currently pressed key and its label as a message in the command line
      triggers = 'auto', -- automatically setup triggers
      -- triggers = {"<leader>"} -- or specifiy a list manually
      -- list of triggers, where WhichKey should not wait for timeoutlen and show immediately
      triggers_nowait = {
        -- marks
        '`',
        "'",
        'g`',
        "g'",
        -- registers
        '"',
        '<c-r>',
        -- spelling
        'z=',
      },
      triggers_blacklist = {
        -- list of mode / prefixes that should never be hooked by WhichKey
        -- this is mostly relevant for keymaps that start with a native binding
        i = { 'j', 'k' },
        v = { 'j', 'k' },
      },
      -- disable the WhichKey popup for certain buf types and file types.
      -- Disabled by default for Telescope
      disable = {
        buftypes = {},
        filetypes = {},
      },
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    },
  },
  {
    'ghillb/cybu.nvim',
    keys = {
      { '<Left>', '<Plug>(CybuPrev)', desc = 'Previous Buffer' },
      { '<Right>', '<Plug>(CybuNext)', desc = 'Next Buffer' },
      { '<C-Left>', '<Plug>(CybuLastusedPrev)', desc = 'Previous Buffer' },
      { '<C-Right>', '<Plug>(CybuLastusedNext)', desc = 'Next Buffer' },
    },
    config = function()
      require('cybu').setup({
        position = {
          relative_to = 'win',
          anchor = 'center',
        },
        style = {
          path = 'relative',
          path_abbreviation = 'none',
          border = 'rounded',
          separator = ' ',
          prefix = '…',
          padding = 1,
          hide_buffer_id = true,
          devicons = {
            enabled = false, -- enable or disable web dev icons
            colored = false, -- enable color for web dev icons
          },
        },
        display_time = 750, -- time the cybu window is displayed
        exclude = { -- filetypes, cybu will not be active
          'neo-tree',
          'fugitive',
          'qf',
        },
        filter = {
          unlisted = true, -- filter & fallback for unlisted buffers
        },
      })
      -- vim.keymap.set('n', 'K', '<Plug>(CybuPrev)')
      -- vim.keymap.set('n', 'J', '<Plug>(CybuNext)')
    end,
  },
  {
    'rest-nvim/rest.nvim',
    dependencies = { { 'nvim-lua/plenary.nvim' } },
    ft = 'http',
    cmd = { 'Rest', 'RestPreview' },
    config = function()
      require('rest-nvim').setup({
        stay_in_current_window_after_split = true,
      })

      vim.api.nvim_create_user_command(
        'Rest',
        "lua require('rest-nvim').run()<CR>",
        {}
      )
      vim.api.nvim_create_user_command(
        'RestPreview',
        "lua require('rest-nvim').run(true)<CR>",
        {}
      )
    end,
  },
  {
    'folke/zen-mode.nvim',
    cmd = 'ZenMode',
    opts = {
      window = {
        backdrop = 1,
        width = 1,
        height = 1,
        options = {
          signcolumn = 'no', -- disable signcolumn
          number = false, -- disable number column
          relativenumber = false, -- disable relative numbers
          cursorline = false, -- disable cursorline
          cursorcolumn = false, -- disable cursor column
          foldcolumn = '0', -- disable fold column
          list = false, -- disable whitespace characters
        },
      },
      plugins = {
        options = {
          enabled = true,
          ruler = false, -- disables the ruler text in the cmd line area
          showcmd = false, -- disables the command in the last line of the screen
          laststatus = 0, -- turn off the statusline in zen mode
        },
        -- gitsigns = true,
        -- tmux = true,
        kitty = { enabled = false, font = '+2' },
      },
      on_open = function()
        require('ibl').update({ enabled = false })
      end,
      -- callback where you can add custom code when the Zen window closes
      on_close = function()
        require('ibl').update({ enabled = true })
      end,
    },
    keys = { { '<leader>z', '<cmd>ZenMode<cr>', desc = 'Zen Mode' } },
  },
  -- {
  --   'folke/trouble.nvim',
  --   dependencies = { 'echasnovski/mini.base16' },
  --   cmd = { 'Trouble', 'TroubleClose', 'TroubleToggle', 'TroubleRefresh' },
  --   config = function()
  --     require('trouble').setup({
  --       icons = false,
  --       indent_lines = false,
  --       use_diagnostic_signs = true,
  --       fold_open = 'v',
  --       fold_closed = '>',
  --     })
  --   end,
  -- },
}, {
  defaults = {
    lazy = true, -- should plugins be lazy-loaded?
  },
  ui = {
    icons = {
      cmd = '',
      config = '',
      event = '',
      ft = '',
      init = '',
      keys = '',
      plugin = '',
      runtime = '',
      require = '',
      source = '',
      start = '',
      task = '',
      lazy = '',
    },
  },
  profiling = {
    loader = false,
    require = false,
  },
})

-- TODO: oscyank?
-- let g:oscyank_silent = v:true
-- let g:oscyank_term = 'default'
-- autocmd TextYankPost * if v:event.operator is 'y' && v:event.regname is '' | execute 'OSCYankRegister "' | endif
