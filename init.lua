---@diagnostic disable: lowercase-global, missing-fields, redefined-local

vim.cmd([[
if !empty(&viminfo)
  set viminfo^=!
endif

filetype plugin on
filetype plugin indent on
syntax manual
au FileType help,qf setl nowrap nofen nospell nocul nolist

cmap WQ wq
cmap wQ wq
cmap w!! w !sudo tee % >/dev/null

nnoremap <silent><Down> n
nnoremap <silent><expr> n (v:searchforward ? 'n' : 'N')
nnoremap <silent><Up> N
nnoremap <silent><expr> N (v:searchforward ? 'N' : 'n')

vnoremap <silent><Down> n
vnoremap <silent><expr> n (v:searchforward ? 'n' : 'N')
vnoremap <silent><Up> N
vnoremap <silent><expr> N (v:searchforward ? 'N' : 'n')

nnoremap <expr> j (v:count == 0 && &wrap) ? 'gj' : 'j'
nnoremap <expr> k (v:count == 0 && &wrap) ? 'gk' : 'k'
nnoremap <expr> 0 (&wrap) ? 'g0' : '0'
nnoremap <expr> ^ (&wrap) ? 'g^' : '^'
nnoremap <expr> $ (&wrap) ? 'g$' : '$'

aunmenu PopUp
autocmd! nvim.popupmenu
]])

local dotenv = require('yyxi.utilities.dotenv')

require('editorconfig').properties.quote_type = function(bufnr, value)
  if value == 'single' or value == 'double' then vim.b[bufnr].quote_type = value end
end

local list_eol_namespace = vim.api.nvim_create_namespace('list_eol')

local function list_eol_refresh(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, list_eol_namespace, 0, -1)
  local topline = vim.fn.line('w0') - 1
  local botline = vim.fn.line('w$')
  for lnum = topline, botline - 1 do
    local line = vim.api.nvim_buf_get_lines(bufnr, lnum, lnum + 1, false)[1]
    if line ~= '' then
      vim.api.nvim_buf_set_extmark(bufnr, list_eol_namespace, lnum, #line, {
        virt_text = { { '↳', 'NonText' } },
        virt_text_pos = 'overlay',
        hl_mode = 'combine',
      })
    end
  end
end

local prose_group = vim.api.nvim_create_augroup('ProseSettings', { clear = true })

vim.api.nvim_create_autocmd('FileType', {
  group = prose_group,
  pattern = { 'markdown', 'text' },
  callback = function(args)
    vim.opt_local.wrap = true
    -- vim.opt_local.conceallevel = 2
    -- vim.opt_local.concealcursor = ''

    vim.api.nvim_create_autocmd({ 'BufWinEnter', 'TextChanged', 'TextChangedI', 'WinScrolled' }, {
      group = prose_group,
      buffer = args.buf,
      callback = function(args) list_eol_refresh(args.buf) end,
    })
  end,
})

vim.diagnostic.config({
  virtual_text = false,
  virtual_lines = false,
  signs = false,
  -- signs = true,
  float = {
    -- source = 'always',
    close_events = { 'BufHidden', 'CursorMoved', 'InsertEnter' },
    focusable = false,
    style = 'minimal',
    border = 'rounded',
  },
  underline = {
    severity = { min = vim.diagnostic.severity.HINT },
  },
  -- underline = true,
  update_in_insert = false,
  severity_sort = true,
})

-- https://github.com/echasnovski/neovim/blob/master/runtime/lua/vim/_defaults.lua
vim.keymap.del({ 'n', 'x' }, 'gc')
vim.keymap.del('n', 'gcc')
vim.keymap.del({ 'o' }, 'gc')

function custom_fold_text() return vim.fn.getline(vim.v.foldstart) end

local function concat(t1, t2)
  for _, v in ipairs(t2) do
    table.insert(t1, v)
  end
  return t1
end

-- Function to get the directory name from a file path
local function dirname(path)
  -- Normalize the path by removing trailing slashes
  local normalized_path = path:gsub('/*$', '')

  -- Find the last slash in the normalized path
  local last_slash = normalized_path:match('.*()/')

  -- If no slash is found, return "."
  if not last_slash then return '.' end

  -- Return the part of the string before the last slash
  return normalized_path:sub(1, last_slash - 1)
end

local function python3_path()
  ---@diagnostic disable-next-line: undefined-field
  local stat = vim.uv.fs_stat(vim.fn.expand('~/.vim/.venv/bin'))
  if not stat then return nil end

  if stat.type == 'directory' then return vim.fn.expand('~/.vim/.venv/bin/python3') end

  return nil
end

local function mason_path()
  local directory = vim.fn.expand(vim.fn.stdpath('data') .. '/mason/bin')
  ---@diagnostic disable-next-line: undefined-field
  local stat = vim.uv.fs_stat(directory)
  if not stat then return nil end

  if stat.type == 'directory' then
    vim.env.PATH = vim.env.PATH .. ':' .. vim.fn.expand(directory)
  end
end

mason_path()

vim.g.python3_host_prog = python3_path()

if vim.g.python3_host_prog then
  vim.env.PATH = vim.env.PATH .. ':' .. dirname(vim.fn.expand(vim.g.python3_host_prog))
end

if vim.loader then vim.loader.enable() end

local function is_installed(binary)
  -- Split PATH into individual directories
  local path_dirs = vim.split(vim.env.PATH or '', ':', { trimempty = true })
  -- Check each directory for the binary
  for _, dir in ipairs(path_dirs) do
    local full_path = dir .. package.config:sub(1, 1) .. binary
    ---@diagnostic disable-next-line: undefined-field
    if vim.uv.fs_stat(full_path) then return true end
  end

  return false
end

-- Define the ternary function
local function ternary(condition, true_value, false_value)
  true_value = true_value or nil
  false_value = false_value or nil
  return condition and true_value or false_value
end

-- vim.api.nvim_set_keymap('n', '<c-w>j', { noremap = true, silent = true, desc = 'Go to the down window' })
-- vim.api.nvim_set_keymap('n', '<c-w>k', { noremap = true, silent = true, desc = 'Go to the up window' })
-- vim.api.nvim_set_keymap('n', '<c-w>l', { noremap = true, silent = true, desc = 'Go to the right window' })
-- vim.api.nvim_set_keymap('n', '<c-w>h', { noremap = true, silent = true, desc = 'Go to the left window' })

-- Using expression mappings for conditional behavior

-- vim.o.wildmode = 'list:longest,full'
-- vim.o.guicursor = 'a:blinkon0'
-- vim.o.mouse = 'nvi'
-- vim.o.complete = ''
vim.g.have_nerd_font = false
vim.g.loaded_matchit = 1
vim.g.loaded_netrw = true
vim.g.loaded_netrwPlugin = true
vim.o.autoindent = true
vim.o.autoread = true
vim.o.background = 'dark'
vim.o.backspace = 'indent,eol,start'
vim.o.backup = true
vim.o.backupcopy = 'yes'
vim.o.backupdir = vim.fn.expand('~/.vim/tmp/backup')
vim.o.breakindent = true
vim.o.breakindentopt = 'shift:0,min:0,sbr'
vim.o.clipboard = 'unnamedplus'
vim.o.cmdheight = 2
vim.o.colorcolumn = ''
vim.o.compatible = false
vim.o.cursorline = false
vim.o.directory = vim.fn.expand('~/.vim/tmp/sessions')
vim.o.display = 'lastline'
vim.o.encoding = 'utf-8'
vim.o.errorbells = false
vim.o.expandtab = true
vim.o.fileencoding = 'utf-8'
vim.o.fillchars = vim.o.fillchars .. 'fold: '
vim.o.foldcolumn = '0'
vim.o.foldenable = true
vim.o.foldlevelstart = 99
vim.o.formatoptions = 'jcroqln'
vim.o.guicursor = 'n-v-c-sm:block,i-ci-ve:ver25,r-cr-o:hor20,a:Cursor/lCursor'
vim.o.hidden = true
vim.o.history = 5000
vim.o.hlsearch = true
vim.o.ignorecase = true
vim.o.inccommand = 'split'
vim.o.incsearch = true
vim.o.iskeyword = '@,48-57,_,192-255,-'
vim.o.joinspaces = false
vim.o.langremap = false
vim.o.laststatus = 3
vim.o.lazyredraw = false
vim.o.linebreak = true
vim.o.list = false
vim.o.listchars = 'tab:¨¨,eol:↳,trail:·'
vim.o.matchtime = 2
vim.o.mouse = 'a'
vim.o.mousemoveevent = true
vim.o.nrformats = 'bin,hex'
vim.o.number = false
vim.o.numberwidth = 6
vim.o.pumblend = 10
vim.o.pumheight = 20
vim.o.relativenumber = false
vim.o.ruler = false
vim.o.scrolljump = 1
vim.o.scrolloff = 0
vim.o.secure = true
vim.o.shada = "'100,<50,s10,:1000,/100,@100,h"
vim.o.shiftwidth = 2
vim.o.shortmess = 'AIOTWacfilmnortxs'
vim.o.showbreak = ''
vim.o.showmatch = false
vim.o.showmode = false
vim.o.showmode = false
vim.o.sidescroll = 1
vim.o.sidescrolloff = 4
vim.o.signcolumn = 'no'
vim.o.smartcase = true
vim.o.smartindent = true
vim.o.smarttab = true
vim.o.softtabstop = 2
vim.o.spell = false
vim.o.splitbelow = true
vim.o.splitkeep = 'screen'
vim.o.splitright = true
vim.o.startofline = false
vim.o.swapfile = false
vim.o.tabpagemax = 50
vim.o.tabstop = 2
vim.o.termguicolors = true
vim.o.timeout = true
vim.o.timeoutlen = 500
vim.o.ttyfast = true
vim.o.undodir = vim.fn.expand('~/.vim/tmp/undo')
vim.o.undofile = true
vim.o.updatetime = 250
vim.o.virtualedit = 'block'
vim.o.virtualedit = 'block'
vim.o.virtualedit = 'onemore'
vim.o.visualbell = false
vim.o.whichwrap = 'b,s,<,>,h,l'
vim.o.wildignore =
'*/.git/*,*/.hg/*,*/.svn/*,*.aux,*.out,*.toc,*.jpg,*.bmp,*.gif,*.luac,*.o,*.obj,*.exe,*.dll,*.manifest,*.spl,*.py[co]'
vim.o.wildmenu = true
vim.o.wildmode = 'longest:full,full'
vim.o.winblend = 10
vim.o.wrap = false
vim.o.wrapscan = false

local noop = function() end

vim.g.clipboard = {
  name = 'OSC 52',
  cache_enabled = false,
  copy = {
    ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
    ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
  },
  paste = {
    ['+'] = function() return 0 end,
    ['*'] = function() return 0 end,
  },
}

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
---@diagnostic disable-next-line: undefined-field
if not vim.uv.fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system({
    'git',
    'clone',
    '--filter=blob:none',
    '--branch=stable',
    lazyrepo,
    lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { 'Failed to clone lazy.nvim:\n', 'ErrorMsg' },
      { out,                            'WarningMsg' },
      { '\nPress any key to exit...' },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

vim.keymap.set('n', ' ', '<Nop>', { silent = true, remap = false })
vim.g.mapleader = ' '
vim.opt.rtp:prepend(lazypath)
vim.g.editorconfig = true

vim.filetype.add({
  extension = {
    tfvars = 'terraform',
    tfstate = 'json',
  },
  filename = {
    ['gitconfig'] = 'gitconfig',
    ['.ansible-lint'] = 'yaml',
    ['fish_history'] = 'yaml',
    ['go.sum'] = 'go',
    ['yarn.lock'] = 'yaml',
    ['.prettierignore'] = 'gitignore',
    ['.eslintignore'] = 'gitignore',
    ['api-extractor.json'] = 'jsonc',
  },
  pattern = {
    ['.*%.js%.map'] = 'json',
    ['.*%.postman_collection'] = 'json',
    ['.*/playbooks/.*%.yaml'] = 'yaml.ansible',
    ['.*/playbooks/.*%.yml'] = 'yaml.ansible',
    ['.*/roles/.*%.yaml'] = 'yaml.ansible',
    ['.*/roles/.*%.yml'] = 'yaml.ansible',
    ['.*/host_vars/.*%.ya?ml'] = 'yaml.ansible',
    ['.*/group_vars/.*%.ya?ml'] = 'yaml.ansible',
    ['.*/group_vars/.*/.*%.ya?ml'] = 'yaml.ansible',
    ['.*/playbook.*%.ya?ml'] = 'yaml.ansible',
    ['.*/playbooks/.*%.ya?ml'] = 'yaml.ansible',
    ['.*/roles/.*/tasks/.*%.ya?ml'] = 'yaml.ansible',
    ['.*/roles/.*/handlers/.*%.ya?ml'] = 'yaml.ansible',
    ['.*/tasks/.*%.ya?ml'] = 'yaml.ansible',
    ['.*/meta/.*%.ya?ml'] = 'yaml.ansible',
  },
})

require('lazy').setup({
  {
    'farmergreg/vim-lastplace',
    lazy = false,
    priority = 1000,
  },
  {
    'nvim-lua/plenary.nvim',
    lazy = true,
    pin = true,
  },
  {
    'echasnovski/mini.base16',
    lazy = false,    -- make sure we load this during startup if it is your main colorscheme
    branch = 'stable',
    priority = 1000, -- make sure to load this before all the other start plugins
    config = function()
      require('yyxi.plugins.mini_base16').setup()
    end,
  },
  {
    'nvim-lualine/lualine.nvim',
    event = 'VimEnter',
    priority = 800,
    config = function()
      require('yyxi.plugins.lualine').setup()
    end,
  },
  {
    'folke/snacks.nvim',
    priority = 1000,
    lazy = false,
    config = function()
      require('yyxi.plugins.snacks').setup()
    end,
  },
  {
    'echasnovski/mini.bufremove',
    event = 'VimEnter',
    keys = {
      {
        '<leader>q',
        function() require('mini.bufremove').delete() end,
        desc = 'Delete buffer',
      },
      {
        '<leader>Q',
        '<cmd>qa<cr>',
        desc = 'Quit Neovim',
      },
      -- {
      --   '<leader>Q',
      --   function()
      --     require('mini.bufremove').wipeout()
      --   end,
      --   desc = 'Wipeout buffer',
      -- },
    },
  },
  {
    'lukas-reineke/indent-blankline.nvim',
    name = 'ibl',
    event = 'VeryLazy',
    config = function()
      require('yyxi.plugins.indent_blankline').setup()
    end,
  },
  {
    'echasnovski/mini.hipatterns',
    branch = 'stable',
    event = 'VeryLazy',
    config = function()
      require('yyxi.plugins.mini_hipatterns').setup()
    end,
  },
  {
    'mason-org/mason.nvim',
    cmd = {
      'Mason',
      'MasonInstall',
      'MasonUninstall',
      'MasonUninstallAll',
      'MasonLog',
    },
    build = function()
      pcall(function() require('mason-registry').refresh() end)
    end,
    config = function()
      require('yyxi.plugins.mason').setup()
    end,
  },
  {
    'nvimtools/none-ls.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'neovim/nvim-lspconfig',
    },
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      require('yyxi.plugins.none_ls').setup({
        is_installed = is_installed,
      })
    end,
  },
  {
    'folke/lazydev.nvim',
    ft = 'lua',
    dependencies = { 'neovim/nvim-lspconfig' },
    config = function()
      require('yyxi.plugins.lazydev').setup()
    end,
  },
  {
    'neovim/nvim-lspconfig',
    cmd = { 'LspInfo', 'LspInstall', 'LspStart' },
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = {
      {
        'mason-org/mason-lspconfig.nvim',
        dependencies = { 'mason-org/mason.nvim' },
        config = noop,
      },
      {
        'b0o/schemastore.nvim',
        config = noop,
      },
      { 'nvim-telescope/telescope.nvim' },
    },
    config = function()
      require('yyxi.plugins.lsp').setup({
        concat = concat,
        is_installed = is_installed,
        ternary = ternary,
      })
    end,
  },
  {
    dir = '~/.vim/local/lsp-fix',
    dependencies = { 'neovim/nvim-lspconfig' },
    keys = {
      {
        '<leader>F',
        function() require('lsp-fix').fix() end,
        desc = 'Fix',
      },
    },
    config = function()
      require('yyxi.plugins.lsp_fix').setup()
    end,
  },
  {
    'stevearc/conform.nvim',
    cmd = { 'ConformInfo' },
    dependencies = { 'neovim/nvim-lspconfig' },
    keys = {
      {
        '<leader>f',
        function() require('conform').format({ async = true, lsp_format = 'first' }) end,
        desc = 'Format',
      },
    },
    config = function()
      require('yyxi.plugins.conform').setup()
    end,
    init = function()
      -- If you want the formatexpr, here is the place to set it
      vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
    end,
  },
  {
    'saghen/blink.cmp',
    version = '1.*',
    event = 'InsertEnter',
    dependencies = {
      { 'neovim/nvim-lspconfig' },
      { 'rafamadriz/friendly-snippets' },
      {
        'L3MON4D3/LuaSnip',
        version = 'v2.*',
        build = 'make install_jsregexp',
        config = noop,
        dependencies = { { 'rafamadriz/friendly-snippets' } },
      }
    },
    config = function()
      require('yyxi.plugins.blink_cmp').setup()
    end,
  },
  {
    'Wansmer/treesj',
    keys = {
      { '<leader>j', '<cmd>TSJToggle<cr>', desc = 'Join Toggle' },
    },
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    config = function()
      require('yyxi.plugins.treesj').setup()
    end,
  },
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'master',
    event = { 'BufReadPre', 'BufNewFile' },
    cmd = {
      'TSInstall',
      'TSUninstall',
      'TSUpdate',
      'TSUpdateSync',
      'TSInstallInfo',
      'TSInstallSync',
      'TSInstallFromGrammar',
    },
    dependencies = {
      -- :lua print(vim.inspect(vim.treesitter.query.get_files('typescript', 'textobjects')))
      { 'nvim-treesitter/nvim-treesitter-textobjects', config = noop },
    },
    -- init = function(plugin)
    --   require('lazy.core.loader').add_to_rtp(plugin)
    --   require('nvim-treesitter.query_predicates')
    -- end,
    -- lazy = false,
    build = ':TSUpdate',
    init = function()
      vim.wo.foldmethod = 'expr'
      vim.wo.foldexpr = 'nvim_treesitter#foldexpr()'
      vim.wo.foldtext = 'v:lua.custom_fold_text()'
      -- vim.wo.foldtext = "nvim_treesitter#foldtext()"
      vim.o.indentexpr = 'nvim_treesitter#indent()'
    end,
    config = function()
      require('yyxi.plugins.treesitter').setup()
    end,
  },
  {
    'Julian/lean.nvim',
    event = { 'BufReadPre *.lean', 'BufNewFile *.lean' },
    ft = 'lean',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
      'saghen/blink.cmp',
    },
    config = function()
      require('yyxi.plugins.lean').setup()
    end,
  },
  {
    'andymass/vim-matchup',
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
    },
    event = { 'BufReadPre', 'BufNewFile' },
    init = function()
      -- vim.g.matchup_matchparen_offscreen =
      --   { method = 'popup', syntax_hl = 1, border = 'rounded', highlight = 'Normal' }
      -- vim.g.matchup_transmute_enabled = 1
      vim.g.matchup_treesitter_disable_virtual_text = 1
      vim.g.matchup_matchparen_offscreen = {}
      vim.g.matchup_matchparen_enabled = 1
      vim.g.matchup_mouse_enabled = 0
      vim.g.matchup_matchparen_deferred = 1
      vim.g.matchup_matchparen_hi_surround_always = 0
      vim.g.matchup_motion_override_Npercent = 0
      vim.g.matchup_matchpref = { html = { nolists = 1, tagnameonly = 1 } }
      vim.g.matchup_matchparen_nomode = 'i'
      vim.g.matchup_motion_override_Npercent = 0
    end,
  },
  {
    'windwp/nvim-ts-autotag',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    ft = { 'html', 'vue' },
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      require('yyxi.plugins.ts_autotag').setup()
    end,
  },
  {
    'numToStr/Comment.nvim',
    event = { 'VeryLazy' },
    -- keys = { { "gc", mode = { "n", "v" } }, { "gb", mode = { "n", "v" } } },
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'JoosepAlviste/nvim-ts-context-commentstring',
    },
    config = function()
      require('yyxi.plugins.comment').setup()
    end,
  },
  {
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    config = function()
      require('yyxi.plugins.autopairs').setup()
    end,
  },
  {
    'gbprod/yanky.nvim',
    event = 'InsertEnter',
    keys = {
      { 'Y', '<Plug>(YankyYank)', mode = { 'n', 'x' }, desc = 'Yank text' },
      { 'y', '<Plug>(YankyYank)', mode = { 'n', 'x' }, desc = 'Yank text' },
    },
    config = function()
      require('yyxi.plugins.yanky').setup()
    end,
  },
  {
    'nvim-telescope/telescope.nvim',
    commit = 'b4da76be54691e854d3e0e02c36b0245f945c2c7',
    dependencies = {
      'nvim-lua/plenary.nvim',
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make',
        cond = function() return vim.fn.executable('make') == 1 end,
      },
      'nvim-telescope/telescope-ui-select.nvim',
      'nvim-treesitter/nvim-treesitter',
      -- 'neovim/nvim-lspconfig',
      'gbprod/yanky.nvim',
    },
    cmd = { 'Telescope' },
    keys = {
      -- {
      --   '<leader>Tt',
      --   '<cmd>Telescope treesitter<cr>',
      --   desc = 'Treesitter Symbols',
      -- },
      {
        '<leader>S',
        '<cmd>Telescope lsp_document_symbols<cr>',
        desc = 'Document Symbols',
      },
      {
        '<leader>W',
        '<cmd>Telescope lsp_workspace_symbols<cr>',
        desc = 'Workspace Symbols',
      },
      { '<leader>g', '<cmd>Telescope live_grep<cr>',    desc = 'Grep' },
      { '<leader>y', '<cmd>Telescope yank_history<cr>', desc = 'Yank History' },
      { '<leader>e', '<cmd>Telescope find_files<cr>',   desc = 'Edit' },
      { '<leader>b', '<cmd>Telescope buffers<cr>',      desc = 'Buffers' },
      {
        '<leader>d',
        '<cmd>Telescope lsp_definitions<cr>',
        desc = 'Definition',
      },
      {
        '<leader>i',
        '<cmd>Telescope lsp_implementations<cr>',
        desc = 'Implementations',
      },
      {
        '<leader>t',
        '<cmd>Telescope lsp_type_definitions<cr>',
        desc = 'Type Definitions',
      },
      { '<leader>R', '<cmd>Telescope lsp_references<cr>', desc = 'References' },
    },
    config = function()
      require('yyxi.plugins.telescope').setup()
    end,
  },
  {
    'echasnovski/mini.ai',
    branch = 'stable',
    version = '*',
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
    },
    config = function()
      require('yyxi.plugins.mini_ai').setup()
    end,
  },
  {
    'echasnovski/mini.surround',
    branch = 'stable',
    -- event = 'InsertEnter',
    -- event = { 'VeryLazy' },
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
    },
    config = function()
      require('yyxi.plugins.mini_surround').setup()
    end,
  },
  {
    'folke/flash.nvim',
    event = 'VeryLazy',
    config = function()
      require('yyxi.plugins.flash').setup()
    end,
    keys = {
      {
        '<c-s>',
        mode = { 'c' },
        function() require('flash').toggle() end,
        desc = 'Toggle Flash Search',
      },
      {
        'vv',
        mode = { 'n', 'x', 'o' },
        function() require('flash').treesitter() end,
        desc = 'Treesitter Visual',
      },
    },
  },
  {
    'sQVe/sort.nvim',
    event = 'InsertEnter',
    keys = {
      {
        '<leader>S',
        '<Esc><Cmd>Sort<CR>',
        desc = 'Sort',
        silent = true,
        mode = 'x',
      },
      -- { '', '<Plug>SortMotion', desc = 'Sort' },
      -- { '', '<Plug>SortLines', desc = 'Sort Lines' },
    },
  },
  {
    'echasnovski/mini.align',
    branch = 'stable',
    keys = { { '<leader>a', mode = { 'n', 'x' }, desc = 'Align' } },
    config = function()
      require('yyxi.plugins.mini_align').setup()
    end,
  },
  {
    'folke/which-key.nvim',
    cmd = 'WhichKey',
    event = 'VeryLazy',
    keys = {
      {
        '<leader>?',
        function() require('which-key').show({ global = true }) end,
        desc = 'Which Key',
      },
    },
    config = function()
      require('yyxi.plugins.which_key').setup()
    end,
  },
  {
    'BranimirE/fix-auto-scroll.nvim',
    config = true,
    event = 'VeryLazy',
  },
  {
    'ghillb/cybu.nvim',
    keys = {
      { '<Left>',  '<Plug>(CybuPrev)', desc = 'Previous Buffer' },
      { '<Right>', '<Plug>(CybuNext)', desc = 'Next Buffer' },
      -- { '<C-Left>', '<Plug>(CybuLastusedPrev)', desc = 'Previous Buffer' },
      -- { '<C-Right>', '<Plug>(CybuLastusedNext)', desc = 'Next Buffer' },
      {
        '<leader><leader>',
        '<Plug>(CybuLastusedNext)',
        desc = 'Switch Buffer',
      },
    },
    config = function()
      require('yyxi.plugins.cybu').setup()
    end,
  },
  {
    'folke/zen-mode.nvim',
    keys = {
      {
        '<leader>z',
        function() require('zen-mode').toggle({}) end,
        desc = 'Zen Mode',
      },
    },
    config = function()
      require('yyxi.plugins.zen_mode').setup()
    end,
  },
  {
    'hrsh7th/nvim-gtd',
    event = { 'BufReadPre', 'BufNewFile' },
    keys = {
      -- { "<C-h>", function() require("foldnav").goto_start() end },
      {
        'gf',
        mode = { 'n', 'v' },
        desc = 'Go to file',
        function() require('gtd').exec({ command = 'edit' }) end,
      },
    },
    config = function()
      require('yyxi.plugins.gtd').setup()
    end,
  },
  {
    'johmsalas/text-case.nvim',
    -- dependencies = { 'nvim-telescope/telescope.nvim' },
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      require('yyxi.plugins.text_case').setup()
    end,
  },
  {
    'danymat/neogen',
    dependencies = { 'saghen/blink.cmp' },
    cmd = 'Neogen',
    keys = {
      {
        '<leader>D',
        mode = { 'n' },
        desc = 'Documentation Comment',
        function() require('neogen').generate() end,
      },
    },
    config = function()
      require('yyxi.plugins.neogen').setup()
    end,
  },
}, {
  defaults = {
    lazy = true,
  },
  ui = {
    title = '',
    border = 'rounded',
    backdrop = 100,
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
  performance = {
    rtp = {
      disabled_plugins = {
        '2html_plugin',
        'bugreport',
        'compiler',
        'ftplugin',
        'getscript',
        'getscriptPlugin',
        'logipat',
        'matchit',
        'matchparen',
        'netrw',
        'netrwFileHandlers',
        'netrwPlugin',
        'netrwSettings',
        'optwin',
        'rplugin',
        'rrhelper',
        'spellfile_plugin',
        'spellfile_plugin',
        'synmenu',
        'syntax',
        'tohtml',
        'tutor',
        'vimball',
        'vimballPlugin',
      },
    },
  },
})
