---@diagnostic disable: lowercase-global

vim.cmd([[
if !empty(&viminfo)
  set viminfo^=!
endif

filetype plugin on
filetype plugin indent on
syntax off
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

local environment = require('yyxi.utilities.environment')
local filetypes = require('yyxi.utilities.filetypes')

environment.configure()

require('editorconfig').properties.quote_type = function(bufnr, value)
  if value == 'single' or value == 'double' then vim.b[bufnr].quote_type = value end
end

local list_eol_namespace = vim.api.nvim_create_namespace('list_eol')

---@param bufnr integer
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

---@return string
function custom_fold_text() return vim.fn.getline(vim.v.foldstart) end

if vim.loader then vim.loader.enable() end

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

---@return nil
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
local plugin_root = environment.lazy_root()
local plugin_manager_path = environment.plugin_manager_path()

---@diagnostic disable-next-line: undefined-field
local lazy_available = vim.uv.fs_stat(plugin_manager_path) ~= nil
if lazy_available then
  vim.opt.rtp:prepend(plugin_manager_path)
else
  vim.api.nvim_echo({
    { 'lazy.nvim is missing at ' .. plugin_manager_path .. '\n', 'WarningMsg' },
    { 'Run ./manage install to materialize locked Git worktrees.' },
  }, true, {})
end

vim.keymap.set('n', ' ', '<Nop>', { silent = true, remap = false })
vim.g.mapleader = ' '
vim.g.editorconfig = true

vim.filetype.add(filetypes.filetype_add_spec())

---@type LazySpec
local plugin_specs = {
  {
    'farmergreg/vim-lastplace',
    dir = environment.vendored_plugin_path('vim-lastplace'),
    lazy = false,
    priority = 1000,
  },
  {
    'nvim-lua/plenary.nvim',
    dir = environment.git_worktree_path('plenary.nvim'),
    lazy = true,
  },
  {
    'nvim-mini/mini.base16',
    dir = environment.git_worktree_path('mini.base16'),
    lazy = false, -- make sure we load this during startup if it is your main colorscheme
    branch = 'stable',
    priority = 1000, -- make sure to load this before all the other start plugins
    config = function() require('yyxi.plugins.colorscheme').setup() end,
  },
  {
    'nvim-lualine/lualine.nvim',
    dir = environment.git_worktree_path('lualine.nvim'),
    event = 'VimEnter',
    priority = 800,
    config = function() require('yyxi.plugins.interface').lualine() end,
  },
  {
    'folke/snacks.nvim',
    dir = environment.git_worktree_path('snacks.nvim'),
    priority = 1000,
    lazy = false,
    config = function() require('yyxi.plugins.interface').snacks() end,
  },
  {
    'nvim-mini/mini.bufremove',
    dir = environment.git_worktree_path('mini.bufremove'),
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
    dir = environment.git_worktree_path('ibl'),
    name = 'ibl',
    event = 'VeryLazy',
    config = function() require('yyxi.plugins.interface').indent_blankline() end,
  },
  {
    'nvim-mini/mini.hipatterns',
    dir = environment.git_worktree_path('mini.hipatterns'),
    event = 'VeryLazy',
    config = function() require('yyxi.plugins.syntax').mini_hipatterns() end,
  },
  {
    'nvimtools/none-ls.nvim',
    dir = environment.git_worktree_path('none-ls.nvim'),
    dependencies = {
      'nvim-lua/plenary.nvim',
      'neovim/nvim-lspconfig',
    },
    event = { 'BufReadPre', 'BufNewFile' },
    config = function() require('yyxi.plugins.language_tools').none_ls() end,
  },
  {
    'neovim/nvim-lspconfig',
    dir = environment.git_worktree_path('nvim-lspconfig'),
    cmd = { 'LspInfo', 'LspInstall', 'LspStart' },
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = {
      {
        'b0o/schemastore.nvim',
        dir = environment.git_worktree_path('schemastore.nvim'),
        config = noop,
      },
      { 'nvim-telescope/telescope.nvim' },
    },
    keys = {
      {
        '<leader>F',
        function() require('yyxi.lsp.fix').fix() end,
        desc = 'Fix',
      },
    },
    config = function() require('yyxi.plugins.language_tools').lsp() end,
  },
  {
    'stevearc/conform.nvim',
    dir = environment.git_worktree_path('conform.nvim'),
    cmd = { 'ConformInfo' },
    dependencies = { 'neovim/nvim-lspconfig' },
    keys = {
      {
        '<leader>f',
        function() require('conform').format({ async = true, lsp_format = 'first' }) end,
        desc = 'Format',
      },
    },
    config = function() require('yyxi.plugins.language_tools').conform() end,
    init = function()
      -- If you want the formatexpr, here is the place to set it
      vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
    end,
  },
  {
    'saghen/blink.cmp',
    dir = environment.git_worktree_path('blink.cmp'),
    event = 'InsertEnter',
    dependencies = {
      { 'neovim/nvim-lspconfig' },
      {
        'rafamadriz/friendly-snippets',
        dir = environment.git_worktree_path('friendly-snippets'),
      },
      {
        'L3MON4D3/LuaSnip',
        dir = environment.git_worktree_path('LuaSnip'),
        config = noop,
        dependencies = {
          {
            'rafamadriz/friendly-snippets',
            dir = environment.git_worktree_path('friendly-snippets'),
          },
        },
      },
    },
    config = function() require('yyxi.plugins.completion').setup() end,
  },
  {
    'Wansmer/treesj',
    dir = environment.git_worktree_path('treesj'),
    keys = {
      { '<leader>j', '<cmd>TSJToggle<cr>', desc = 'Join Toggle' },
    },
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    config = function() require('yyxi.plugins.editing').treesj() end,
  },
  {
    'nvim-treesitter/nvim-treesitter',
    dir = environment.git_worktree_path('nvim-treesitter'),
    lazy = false,
    init = function() vim.wo.foldtext = 'v:lua.custom_fold_text()' end,
    config = function()
      require('yyxi.plugins.syntax').treesitter()

      for _, command in ipairs({ 'TSInstall', 'TSInstallFromGrammar', 'TSUpdate', 'TSUninstall' }) do
        pcall(vim.api.nvim_del_user_command, command)
      end
    end,
  },
  {
    'Julian/lean.nvim',
    dir = environment.git_worktree_path('lean.nvim'),
    event = { 'BufReadPre *.lean', 'BufNewFile *.lean' },
    ft = 'lean',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
      'saghen/blink.cmp',
    },
    config = function() require('yyxi.plugins.language_tools').lean() end,
  },
  {
    'andymass/vim-matchup',
    dir = environment.git_worktree_path('vim-matchup'),
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
    dir = environment.git_worktree_path('nvim-ts-autotag'),
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    ft = { 'html', 'vue' },
    event = { 'BufReadPre', 'BufNewFile' },
    config = function() require('yyxi.plugins.syntax').ts_autotag() end,
  },
  {
    'numToStr/Comment.nvim',
    dir = environment.vendored_plugin_path('Comment.nvim'),
    event = { 'VeryLazy' },
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      {
        'JoosepAlviste/nvim-ts-context-commentstring',
        dir = environment.vendored_plugin_path('nvim-ts-context-commentstring'),
      },
    },
    config = function() require('yyxi.plugins.editing').comment() end,
  },
  {
    'windwp/nvim-autopairs',
    dir = environment.git_worktree_path('nvim-autopairs'),
    event = 'InsertEnter',
    config = function() require('yyxi.plugins.editing').autopairs() end,
  },
  {
    'gbprod/yanky.nvim',
    dir = environment.git_worktree_path('yanky.nvim'),
    event = 'InsertEnter',
    keys = {
      { 'Y', '<Plug>(YankyYank)', mode = { 'n', 'x' }, desc = 'Yank text' },
      { 'y', '<Plug>(YankyYank)', mode = { 'n', 'x' }, desc = 'Yank text' },
    },
    config = function() require('yyxi.plugins.editing').yanky() end,
  },
  {
    'nvim-telescope/telescope.nvim',
    dir = environment.git_worktree_path('telescope.nvim'),
    dependencies = {
      {
        'nvim-telescope/telescope-ui-select.nvim',
        dir = environment.git_worktree_path('telescope-ui-select.nvim'),
      },
      'nvim-lua/plenary.nvim',
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        dir = environment.git_worktree_path('telescope-fzf-native.nvim'),
      },
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
      { '<leader>g', '<cmd>Telescope live_grep<cr>', desc = 'Grep' },
      { '<leader>y', '<cmd>Telescope yank_history<cr>', desc = 'Yank History' },
      { '<leader>e', '<cmd>Telescope find_files<cr>', desc = 'Edit' },
      { '<leader>b', '<cmd>Telescope buffers<cr>', desc = 'Buffers' },
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
    config = function() require('yyxi.plugins.interface').telescope() end,
  },
  {
    'nvim-mini/mini.ai',
    dir = environment.git_worktree_path('mini.ai'),
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
    },
    -- mini.ai uses textobjects.scm queries copied from nvim-treesitter-textobjects by ./manage.
    config = function() require('yyxi.plugins.editing').mini_ai() end,
  },
  {
    'nvim-mini/mini.surround',
    dir = environment.git_worktree_path('mini.surround'),
    -- event = 'InsertEnter',
    -- event = { 'VeryLazy' },
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
    },
    config = function() require('yyxi.plugins.editing').mini_surround() end,
  },
  {
    'folke/flash.nvim',
    dir = environment.git_worktree_path('flash.nvim'),
    event = 'VeryLazy',
    config = function() require('yyxi.plugins.interface').flash() end,
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
    dir = environment.vendored_plugin_path('sort.nvim'),
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
    'nvim-mini/mini.align',
    dir = environment.git_worktree_path('mini.align'),
    keys = { { '<leader>a', mode = { 'n', 'x' }, desc = 'Align' } },
    config = function() require('yyxi.plugins.editing').mini_align() end,
  },
  {
    'folke/which-key.nvim',
    dir = environment.git_worktree_path('which-key.nvim'),
    cmd = 'WhichKey',
    event = 'VeryLazy',
    keys = {
      {
        '<leader>?',
        function() require('which-key').show({ global = true }) end,
        desc = 'Which Key',
      },
    },
    config = function() require('yyxi.plugins.interface').which_key() end,
  },
  {
    'BranimirE/fix-auto-scroll.nvim',
    dir = environment.vendored_plugin_path('fix-auto-scroll.nvim'),
    config = true,
    event = 'VeryLazy',
  },
  {
    'ghillb/cybu.nvim',
    dir = environment.vendored_plugin_path('cybu.nvim'),
    keys = {
      { '<Left>', '<Plug>(CybuPrev)', desc = 'Previous Buffer' },
      { '<Right>', '<Plug>(CybuNext)', desc = 'Next Buffer' },
      -- { '<C-Left>', '<Plug>(CybuLastusedPrev)', desc = 'Previous Buffer' },
      -- { '<C-Right>', '<Plug>(CybuLastusedNext)', desc = 'Next Buffer' },
      {
        '<leader><leader>',
        '<Plug>(CybuLastusedNext)',
        desc = 'Switch Buffer',
      },
    },
    config = function() require('yyxi.plugins.interface').cybu() end,
  },
  {
    'folke/zen-mode.nvim',
    dir = environment.git_worktree_path('zen-mode.nvim'),
    keys = {
      {
        '<leader>z',
        function() require('zen-mode').toggle({}) end,
        desc = 'Zen Mode',
      },
    },
    config = function() require('yyxi.plugins.interface').zen_mode() end,
  },
  {
    'hrsh7th/nvim-gtd',
    dir = environment.git_worktree_path('nvim-gtd'),
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
    config = function() require('yyxi.plugins.language_tools').gtd() end,
  },
  {
    'johmsalas/text-case.nvim',
    dir = environment.vendored_plugin_path('text-case.nvim'),
    -- dependencies = { 'nvim-telescope/telescope.nvim' },
    event = { 'BufReadPre', 'BufNewFile' },
    config = function() require('yyxi.plugins.editing').text_case() end,
  },
  {
    'danymat/neogen',
    dir = environment.git_worktree_path('neogen'),
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
    config = function() require('yyxi.plugins.editing').neogen() end,
  },
}

---@type LazyConfig
local lazy_options = {
  root = plugin_root,
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
}

if lazy_available then require('lazy').setup(plugin_specs, lazy_options) end
