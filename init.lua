---@diagnostic disable: lowercase-global, missing-fields
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
]])

-- https://github.com/echasnovski/neovim/blob/master/runtime/lua/vim/_defaults.lua
vim.keymap.del({ 'n', 'x' }, 'gc')
vim.keymap.del('n', 'gcc')
vim.keymap.del({ 'o' }, 'gc')

function custom_fold_text()
  return vim.fn.getline(vim.v.foldstart)
end

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
  if not last_slash then
    return '.'
  end

  -- Return the part of the string before the last slash
  return normalized_path:sub(1, last_slash - 1)
end

local function python3_path()
  ---@diagnostic disable-next-line: undefined-field
  local stat = vim.uv.fs_stat(vim.fn.expand('~/.vim/.venv/bin'))
  if not stat then
    return nil
  end

  if stat.type == 'directory' then
    return vim.fn.expand('~/.vim/.venv/bin/python3')
  end

  return nil
end

local function mason_path()
  local directory = vim.fn.expand(vim.fn.stdpath('data') .. 'mason/bin')
  ---@diagnostic disable-next-line: undefined-field
  local stat = vim.uv.fs_stat(directory)
  if not stat then
    return nil
  end

  if stat.type == 'directory' then
    vim.env.PATH = vim.env.PATH .. ':' .. vim.fn.expand(directory)
  end
end

mason_path()

vim.g.python3_host_prog = python3_path()

if vim.g.python3_host_prog then
  vim.env.PATH = vim.env.PATH
    .. ':'
    .. dirname(vim.fn.expand(vim.g.python3_host_prog))
end

if vim.loader then
  vim.loader.enable()
end

local function is_installed(binary)
  -- Split PATH into individual directories
  local path_dirs = vim.split(vim.env.PATH or '', ':', { trimempty = true })
  -- Check each directory for the binary
  for _, dir in ipairs(path_dirs) do
    local full_path = dir .. package.config:sub(1, 1) .. binary
    ---@diagnostic disable-next-line: undefined-field
    if vim.uv.fs_stat(full_path) then
      return true
    end
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
vim.o.guicursor = 'n-v-c-sm:block,i-ci-ve:ver25,r-cr-o:hor20,a:Cursor/lCursor'
vim.g.loaded_matchit = 1
vim.g.have_nerd_font = false
vim.g.loaded_netrw = true
vim.g.loaded_netrwPlugin = true
vim.o.mousemoveevent = true
vim.o.autoindent = true
vim.o.autoread = true
vim.o.background = 'dark'
vim.o.backspace = 'indent,eol,start'
vim.o.backup = true
vim.o.showmatch = false
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
vim.o.fillchars = vim.o.fillchars .. 'fold: '
vim.o.foldenable = true
vim.o.foldlevelstart = 99
vim.o.foldcolumn = '0'
vim.o.foldtext = 'v:lua.custom_fold_text()'
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
vim.o.lazyredraw = false
vim.o.linebreak = true
vim.o.ttyfast = true
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
vim.o.scrolljump = 1
vim.o.scrolloff = 0
vim.o.secure = true
vim.o.shada = "'100,<50,s10,:1000,/100,@100,h"
vim.o.shiftwidth = 2
vim.o.shortmess = 'AIOTWacfilmnortxs'
vim.o.showbreak = '↳ '
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
vim.o.undodir = vim.fn.expand('~/.vim/tmp/undo')
vim.o.undofile = true
vim.o.updatetime = 250
vim.o.virtualedit = 'block'
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
vim.opt.iskeyword:append('-')

local noop = function() end

vim.g.clipboard = {
  name = 'OSC 52',
  cache_enabled = false,
  copy = {
    ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
    ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
  },
  paste = {
    ['+'] = function()
      return 0
    end,
    ['*'] = function()
      return 0
    end,
  },
}

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
      { out, 'WarningMsg' },
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
    'echasnovski/mini.base16',
    lazy = false, -- make sure we load this during startup if it is your main colorscheme
    branch = 'stable',
    priority = 1000, -- make sure to load this before all the other start plugins
    config = function()
      local opts = {
        palette = {
          base00 = '#1d2021',
          base01 = '#3c3836',
          base02 = '#504945',
          base03 = '#665c54',
          base04 = '#bdae93',
          base07 = '#d5c4a1',
          base05 = '#ebdbb2',
          base06 = '#fbf1c7',
          base08 = '#fb4934',
          base09 = '#83a598',
          base0A = '#fabd2f',
          base0B = '#b8bb26',
          base0C = '#8ec07c', -- underused
          base0D = '#fe8019',
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
          ['mason-org/mason.nvim'] = true,
        },
      }

      require('mini.base16').setup(opts)

      -- stylua: ignore start

      local p = opts.palette
      local hi = function(name, data) vim.api.nvim_set_hl(0, name, data) end
      local hm = function(name, data)
        local d = vim.tbl_extend('force',
          vim.api.nvim_get_hl(0,
            { name = data.link, link = false, create = false }), data)
        d.link = nil
        hi(name, d)
      end

      hi('Cursor',
        { force = true, fg = p.base00, bg = p.base06, attr = nil, sp = nil, nocombine = true, italic = true })
      hi('Function',
        { force = true, fg = p.base0D, bg = nil, attr = nil, sp = nil, nocombine = false, })
      hi('Comment',
        { force = true, fg = p.base03, bg = nil, attr = nil, sp = nil, nocombine = false, })
      hi('Delimiter',
        { force = true, fg = p.base09, bg = nil, attr = nil, sp = nil, nocombine = false, })
      hi('Delimiter',
        { force = true, fg = p.base09, bg = nil, attr = nil, sp = nil, nocombine = false, })
      hi('Boolean',
        { force = true, fg = p.base0F, bg = nil, attr = nil, sp = nil, nocombine = false, })
      hi('Float',
        { force = true, fg = p.base0B, bg = nil, attr = nil, sp = nil, nocombine = false, italic = true })
      hi('Number',
        { force = true, fg = p.base0B, bg = nil, attr = nil, sp = nil, nocombine = false, italic = true })
      hi('Constant',
        { force = true, fg = p.base06, bg = nil, attr = nil, sp = nil, nocombine = false })
      hi('Operator',
        { force = true, fg = p.base0C, bg = nil, attr = nil, sp = nil, nocombine = false })
      hi('Structure',
        { force = true, fg = p.base05, bg = nil, attr = nil, sp = nil, nocombine = false })
      hi('Identifier', { force = true, link = 'Normal', })

      hi('Folded',
        { force = true, fg = p.base04, bg = '#262A2B', attr = nil, sp = nil, nocombine = false })

      hi('TelescopeBorder',
        { force = true, fg = p.base01, bg = p.base00 })

      hi('TelescopeTitle',
        { force = true, fg = p.base03, bg = p.base00 })

      -- FIXME https://github.com/microsoft/vscode/issues/97063
      -- TreeSitter Highlights https://github.com/nvim-treesitter/nvim-treesitter/blob/master/CONTRIBUTING.md

      -- Identifiers

      hi('@variable',
        { force = true, fg = p.base05, bg = nil })
      hm('@variable.builtin',
        { force = true, link = '@variable', bold = true })
      hi('@variable.member', { force = true, link = '@variable' })
      hi('@variable.parameter', { force = true, link = '@variable' })
      hm('@variable.parameter.builtin',
        { force = true, link = '@variable.parameter', bold = true })

      hi('@constant', { force = true, link = 'Constant' })
      hm('@constant.builtin',
        { force = true, link = '@constant', bold = true })
      hi('@constant.macro', { force = true, link = 'Macro' })

      hi('@module', { force = true, link = 'Identifier' })
      hm('@module.builtin',
        { force = true, link = '@module', bold = true })
      hi('@label', { force = true, link = 'Label' })

      -- Literals

      hi('@string', { force = true, link = 'String' })
      hi('@string.documentation', { force = true, link = '@string' })
      hm('@string.escape',
        { force = true, link = '@string', bold = true })
      hm('@string.regexp',
        { force = true, link = '@string', italic = true, bold = true })
      hm('@string.special',
        { force = true, link = '@string', italic = true, bold = true })
      hi('@string.special.path', { force = true, link = 'Directory' })
      hi('@string.special.symbol', { force = true, link = '@constant' })
      hi('@string.special.url', { force = true, link = '@markup.link.url' })
      hm('@string.special.url.comment',
        { force = true, link = 'Comment', --[[ underline = true ]] })

      hi('@character', { force = true, link = 'Character' })
      hm('@character.special',
        { force = true, link = '@character', bold = true })

      hi('@boolean', { force = true, link = 'Boolean' })
      hi('@number', { force = true, link = 'Number' })
      hi('@number.float', { force = true, link = 'Float' })

      -- Types

      hi('@type', { force = true, link = 'Type' })
      hm('@type.builtin',
        { force = true, link = '@type', bold = true })
      hi('@type.definition', { force = true, link = 'Typedef' })
      hi('@type.qualifier', { force = true, link = 'StorageClass' })

      hi('@attribute', { force = true, link = 'Macro' })
      hm('@attribute.builtin',
        { force = true, link = '@attribute', bold = true })
      hi('@property', { force = true, link = '@variable' })

      -- Functions

      hi('@function', { force = true, link = 'Function' })
      hm('@function.builtin',
        { force = true, link = '@function', bold = true })
      hm('@function.call',
        { force = true, link = '@function', italic = true })
      hi('@function.macro', { force = true, link = 'Macro' })

      hi('@function.method', { force = true, link = '@function' })
      hi('@function.method.call', { force = true, link = '@function.call' })

      hi('@constructor', { force = true, link = '@function.builtin' })
      hi('@operator', { force = true, link = 'Operator' })

      -- Keywords

      hi('@keyword', { force = true, link = 'Keyword' })
      hi('@keyword.coroutine', { force = true, link = '@keyword' })
      hi('@keyword.debug', { force = true, link = '@keyword' })
      hi('@keyword.exception', { force = true, link = '@keyword' })
      hi('@keyword.function', { force = true, link = '@keyword' })
      hi('@keyword.import', { force = true, link = '@keyword' })
      hi('@keyword.modifier', { force = true, link = '@keyword' })
      hi('@keyword.operator', { force = true, link = '@keyword' })
      hi('@keyword.repeat', { force = true, link = '@keyword' })
      hi('@keyword.return', { force = true, link = '@keyword' })
      hi('@keyword.storage', { force = true, link = '@keyword' })
      hi('@keyword.type', { force = true, link = '@keyword' })

      hi('@keyword.conditional', { force = true, link = 'Conditional' })
      hi('@keyword.conditional.ternary',
        { force = true, link = 'Conditional' })

      hi('@keyword.directive', { force = true, link = '@keyword' })
      hi('@keyword.directive.define',
        { force = true, link = '@keyword.directive' })

      -- Punctuation

      hi('@punctuation', { force = true, link = 'Delimiter' })
      hi('@punctuation.bracket', { force = true, link = '@punctuation' })
      hi('@punctuation.delimiter', { force = true, link = '@punctuation' })
      hm('@punctuation.special',
        { force = true, link = '@punctuation', bold = true })

      -- Comments

      hi('@comment', { force = true, link = 'Comment' })
      hi('@comment.documentation', { force = true, link = '@comment' })

      -- TODO: minihipatterns
      hi('@comment.error', { force = true, link = '@text.danger' })
      hi('@comment.note', { force = true, link = '@text.note' })
      hi('@comment.todo', { force = true, link = '@text.todo' })
      hi('@comment.warning', { force = true, link = '@text.warning' })

      -- Markup

      hi('@markup.strong', { force = true, link = '@text.strong' })
      hi('@markup.italic', { force = true, link = '@text.emphasis' })
      hi('@markup.strikethrough',
        { force = true, link = '@text.strikethrough' })
      hi('@markup.underline', { force = true, link = '@text.underline' })

      hi('@markup.heading', { force = true, link = '@text.title' })
      hi('@markup.heading.1', { force = true, link = '@text.title' })
      hi('@markup.heading.2', { force = true, link = '@text.title' })
      hi('@markup.heading.3', { force = true, link = '@text.title' })
      hi('@markup.heading.4', { force = true, link = '@text.title' })
      hi('@markup.heading.5', { force = true, link = '@text.title' })
      hi('@markup.heading.6', { force = true, link = '@text.title' })

      hi('@markup.quote', { force = true, link = '@string.special' })
      hi('@markup.math', { force = true, link = '@string.special' })

      hi('@markup.link', { force = true, link = '@text.reference' })
      hi('@markup.link.label', { force = true, link = '@markup.link' })
      hi('@markup.link.url',
        { force = true, fg = p.base05, bg = nil, underline = true })

      hi('@markup.raw', { force = true, link = '@text.literal' })
      hi('@markup.raw.block', { force = true, link = '@markup.raw' })

      hi('@markup.list', { force = true, link = '@punctuation.special' })
      hi('@markup.list.checked', { force = true, link = 'DiagnosticOk' })
      hi('@markup.list.unchecked', { force = true, link = 'DiagnosticWarn' })

      hi('@markup.environment', { force = true, link = '@module' })

      -- Other: Text

      hi('@text.strong',
        { force = true, fg = nil, bg = nil, bold = true })
      hi('@text.strike',
        { force = true, fg = nil, bg = nil, strikethrough = true })
      hi('@text.emphasis',
        { force = true, fg = nil, bg = nil, italic = true })
      hi('@text.underline', { force = true, link = 'Underlined' })

      hi('@text.danger', { force = true, link = 'ErrorMsg' })
      hi('@text.literal', { force = true, link = 'Special' })
      hi('@text.note', { force = true, link = 'MoreMsg' })
      hi('@text.reference', { force = true, link = 'Identifier' })
      hi('@text.title', { force = true, link = 'Title' })
      hi('@text.todo', { force = true, link = 'Todo' })
      hi('@text.uri', { force = true, link = 'Underlined' })
      hi('@text.warning', { force = true, link = 'WarningMsg' })

      -- Other

      hi('@diff.delta', { force = true, link = 'Changed' })
      hi('@diff.minus', { force = true, link = 'Removed' })
      hi('@diff.plus', { force = true, link = 'Added' })

      hi('@symbol', { force = true, link = 'Keyword' })

      hi('@tag', { force = true, link = 'Tag' })
      hi('@tag.attribute', { force = true, link = '@tag' })
      hm('@tag.builtin',
        { force = true, link = '@tag', bold = true })
      hi('@tag.delimiter', { force = true, link = '@punctuation' })

      -- Source: `:h lsp-semantic-highlight`

      -- hi('@lsp.type.class',                      { })
      hi('@lsp.type.class', { force = true, link = 'Structure' })
      hi('@lsp.type.comment', { force = true, link = '@comment' })
      hi('@lsp.type.decorator', { force = true, link = '@function' })
      hi('@lsp.type.enum', { force = true, link = '@type' })
      hi('@lsp.type.enumMember', { force = true, link = '@constant' })
      hi('@lsp.type.event', { force = true, link = '@type' })
      hi('@lsp.type.function', { force = true, link = '@function' })
      hi('@lsp.type.interface', { force = true, link = '@type' })
      hi('@lsp.type.keyword', { force = true, link = '@keyword' })
      hi('@lsp.type.macro', { force = true, link = '@function.macro' })
      hi('@lsp.type.method', { force = true, link = '@function.method' })
      hi('@lsp.type.modifier', { force = true, link = '@type.qualifier' })
      hi('@lsp.type.namespace', { force = true, link = '@module' })
      hi('@lsp.type.number', { force = true, link = '@number' })
      hi('@lsp.type.operator', { force = true, link = '@operator' })
      hi('@lsp.type.parameter',
        { force = true, link = '@variable.parameter' })
      hi('@lsp.type.property', { force = true, link = '@property' })
      hi('@lsp.type.regexp', { force = true, link = '@string.regexp' })
      hi('@lsp.type.string', { force = true, link = '@string' })
      hi('@lsp.type.struct', { force = true, link = 'Structure' })
      hi('@lsp.type.type', { force = true, link = '@type' })
      hi('@lsp.type.typeParameter',
        { force = true, link = '@type.definition' })
      hi('@lsp.type.variable', { force = true, link = '@variable' })
      hi('@lsp.typemod.variable.readonly',
        { force = true, link = '@constant' })
      hm('@lsp.typemod.function.async',
        { force = true, link = '@function', bold = true })

      hi('@lsp.mod.defaultLibrary', {})
      hi("@lsp.typemod.function.defaultLibrary", { link = "@function.builtin" })
      hi("@lsp.typemod.method.defaultLibrary", { link = "@function.builtin" })
      hi("@lsp.typemod.variable.defaultLibrary", { link = "@variable.builtin" })
      hi('@lsp.mod.deprecated', { fg = p.base08, bg = nil })
      hi('@lsp.mod.documentation', { link = '@string.documentation' })

      -- TODO: integrate this https://github.com/eldritch-theme/eldritch.nvim/blob/master/lua/eldritch/groups.lua
      hi("@lsp.type.boolean", { link = "@boolean" })
      -- hi("@lsp.type.builtinType", { link = "@type.builtin" })
      hi("@lsp.type.deriveHelper", { link = "@attribute" })
      hi("@lsp.type.escapeSequence", { link = "@string.escape" })
      -- hi("@lsp.type.formatSpecifier", { link = "@markup.list" })
      -- hi("@lsp.type.generic", { link = "@variable" })
      hi("@lsp.type.selfKeyword", { link = "@variable.builtin" })
      hi("@lsp.type.selfTypeKeyword", { link = "@variable.builtin" })
      -- hi("@lsp.type.typeAlias", { link = "@type.def" })
      -- hi("@lsp.typemod.class.defaultLibrary", { link = "@type.builtin" })
      -- hi("@lsp.typemod.enum.defaultLibrary", { link = "@type.builtin" })
      -- hi("@lsp.typemod.enumMember.defaultLibrary", { link = "@constant.builtin" })
      hi("@lsp.typemod.function.defaultLibrary", { link = "@function.builtin" })
      hi("@lsp.typemod.keyword.injected", { link = "@keyword" })
      -- hi("@lsp.typemod.macro.defaultLibrary", { link = "@function.builtin" })
      -- hi("@lsp.typemod.method.defaultLibrary", { link = "@function.builtin" })
      -- hi("@lsp.typemod.operator.injected", { link = "@operator" })
      -- hi("@lsp.typemod.string.injected", { link = "@string" })
      -- -- hi("@lsp.typemod.struct.defaultLibrary", { link = "@type.builtin" })
      -- hi("@lsp.typemod.variable.callable", { link = "@function" })
      -- hi("@lsp.typemod.variable.injected", { link = "@variable" })
      -- hi("@lsp.typemod.variable.static", { link = "@constant" })
      -- hi("@lsp.type.namespace.python", { link = "@variable" })

      -- hi('@lsp.typemod',                 {})
      -- hi('@lsp.mod.abstract',                 {})
      -- hi('@lsp.mod.async',                    {})
      -- hi('@lsp.mod.declaration',              {})
      -- hi('@lsp.mod.definition',               {})
      -- hi('@lsp.mod.deprecated',               {})
      -- hi('@lsp.mod.modification',             {})
      -- hi('@lsp.mod.readonly',                 {})
      -- hi('@lsp.mod.static',                   {})

      -- hm('@lsp.mod.declaration',              { link = "@variable" })
      hi('@type.typescript', { link = "Normal" })

      hi('FlashLabel', { underline = true, bold = true, fg = '#ffffff' })

      hi('IndentBlanklineChar',
        { nocombine = true, ctermbg = nil, ctermfg = 8, bg = nil, fg = '#332E33' })
      hi('IndentBlanklineCharScope',
        {
          nocombine = true,
          ctermbg = nil,
          ctermfg = 8,
          bold = false,
          bg = nil,
          fg =
          '#474247'
        })

      hi('Todo', { force = true, link = 'MiniHipatternsTodo' })
      hi('@comment.todo', { force = true, link = 'MiniHipatternsTodo' })
      hi('NormalFloat', { force = true, link = 'Normal' })
      hi('FloatBorder', { force = true, link = 'Normal' })
      hi('FloatBorder', { force = true, link = 'Normal' })
      hi('NormalFloat', { force = true, link = 'Normal' })
      hi('DiagnosticFloatingError', { force = true, link = 'Normal' })
      hi('DiagnosticFloatingHint', { force = true, link = 'Normal' })
      hi('DiagnosticFloatingInfo', { force = true, link = 'Normal' })
      hi('DiagnosticFloatingWarn', { force = true, link = 'Normal' })
      hi('DiagnosticUnnecessary',
        { force = true, fg = p.base04, bg = nil, nocombine = false })
      hi('WinSeparator', { force = true, link = 'Normal' })
      hi('WhichKeySeparator', { force = true, link = 'String' })
      hi('WhichKeyFloat', { force = true, link = 'Normal' })
      hi('WhichKeyBorder', { force = true, link = 'Normal' })
      hi('ZenBg', { force = true, link = 'Normal' })
      hi('LazyButton', { force = true, link = 'Comment' })
      hi('LazyButtonActive', { force = true, link = 'Normal' })
      hi('LazyH1', { force = true, link = 'Normal' })


      hi('LazyH1', { force = true, link = 'Normal' })

      hi('AvanteConflictCurrent', { force = true, link = 'Normal' })
      hi('AvanteConflictIncoming', { force = true, link = 'Normal' })
      hi('AvanteConflictCurrentLabel', { force = true, link = 'Normal' })
      hi('AvanteConflictIncomingLabel', { force = true, link = 'Normal' })
      hi('AvantePopupHint', { force = true, link = 'Normal' })
      hi('AvanteInlineHint', { force = true, link = 'Normal' })

      hi('Pmenu', { fg = p.base05, bg = p.base00, sp = nil, force = true })
      hi('PmenuExtra', { fg = p.base05, bg = p.base00, sp = nil, force = true })
      hi('PmenuKind', { fg = p.base05, bg = p.base00, sp = nil, force = true })
      hi('PmenuSbar', { fg = nil, bg = p.base01, sp = nil, force = true })
      hi('PmenuThumb', { fg = nil, bg = p.base07, sp = nil, force = true })
      hi('PmenuExtraSel',
        { fg = p.base05, bg = p.base00, reverse = true, sp = nil, force = true })
      hi('PmenuKindSel',
        { fg = p.base05, bg = p.base00, reverse = true, sp = nil, force = true })
      hi('PmenuSel',
        { fg = p.base05, bg = p.base00, reverse = true, sp = nil, force = true })
      hi('PmenuMatch',
        { fg = p.base05, bg = p.base00, bold = true, sp = nil, force = true })
      hi('PmenuMatchSel',
        { fg = p.base05, bg = p.base00, bold = true, reverse = true, sp = nil, force = true })

      hi('CmpItemAbbr', { fg = p.base05, bg = nil, sp = nil, force = true })
      hi('CmpItemAbbrDeprecated',
        { fg = p.base03, bg = nil, sp = nil, force = true })
      hi('CmpItemAbbrMatch',
        { fg = p.base0A, bg = nil, bold = true, sp = nil, force = true })
      hi('CmpItemAbbrMatchFuzzy',
        { fg = p.base0A, bg = nil, bold = true, sp = nil, force = true })
      hi('CmpItemKind', { fg = p.base0F, bg = p.base00, sp = nil, force = true })
      hi('CmpItemMenu', { fg = p.base05, bg = p.base00, sp = nil, force = true })

      hi('BlinkCmpLabelDescription', { force = true, link = 'Comment' })

      -- hi('MasonHeader', { force = true, fg = p.base00, bg = nil, nocombine = true })

      -- hi('@conditional',                      { force = true,     link = 'Conditional' })
      -- hi('@debug',                            { force = true,     link = 'Debug' })
      -- hi('@define',                           { force = true,     link = 'Define' })
      -- hi('@exception',                        { force = true,     link = 'Exception' })
      -- hi('@field',                            { force = true,     link = 'Identifier' })
      -- hi('@float',                            { force = true,     link = 'Float' })
      -- hi('@include',                          { force = true,     link = 'Include' })
      -- hi('@macro',                            { force = true,     link = 'Macro' })
      -- hi('@method',                           { force = true,     link = 'Function' })
      -- hi('@method.call',                      { force = true,     link = 'Function' })
      -- hi('@namespace',                        { force = true,     link = 'Identifier' })
      -- hi('@none',                             { force = true,     link = 'Normal' })
      -- hi('@preproc',                          { force = true,     link = 'PreProc' })
      -- hi('@repeat',                           { force = true,     link = 'Repeat' })
      -- hi('@storageclass',                     { force = true,     link = 'StorageClass' })
      -- hi('@structure',                        { force = true,     link = 'Structure' })

      -- stylua: ignore end
    end,
  },
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'echasnovski/mini.base16' },
    event = 'VimEnter',
    priority = 800,
    opts = {
      extensions = { 'mason', 'lazy', 'man' },
      options = {
        always_divide_middle = true,
        component_separators = '',
        globalstatus = true,
        icons_enabled = false,
        section_separators = '',
        -- theme = 'gruvbox',
        disabled_filetypes = {
          -- TelescopePrompt = {},
          -- mason = {},
          -- lazy = {},
          statusline = {},
          winbar = {},
          help = {},
        },
      },

      sections = {
        lualine_a = { 'mode' },
        lualine_b = { 'branch' },
        lualine_c = { { 'filename', path = 1 } },
        lualine_x = { 'encoding', 'fileformat', 'filetype' },
        lualine_y = { 'progress' },
        lualine_z = { 'location' },
      },
      inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = { 'filename' },
        lualine_x = { 'location' },
        lualine_y = {},
        lualine_z = {},
      },
    },
  },
  {
    'lukas-reineke/indent-blankline.nvim',
    name = 'ibl',
    event = 'VeryLazy',
    dependencies = { 'echasnovski/mini.base16' },
    config = function()
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
    'domharries/foldnav.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    event = 'VeryLazy',
    config = function()
      vim.g.foldnav = {
        flash = {
          enabled = false,
        },
      }
    end,

    keys = {
      -- { "<C-h>", function() require("foldnav").goto_start() end },
      {
        '<C-Right>',
        function()
          require('foldnav').goto_next()
        end,
      },
      {
        '<C-Left>',
        function()
          require('foldnav').goto_prev_start()
        end,
      },
    },
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
    'mason-org/mason.nvim',
    dependencies = { 'echasnovski/mini.base16' },
    -- lazy = false,
    cmd = {
      'Mason',
      'MasonInstall',
      'MasonUninstall',
      'MasonUninstallAll',
      'MasonLog',
    },
    build = function()
      pcall(function()
        require('mason-registry').refresh()
      end)
    end,
    opts = {
      PATH = 'append',
      log_level = vim.log.levels.WARN,
      max_concurrent_installers = 10,
      pip = {
        upgrade_pip = false,
      },
      ui = {
        border = 'rounded',
        width = 0.8,
        height = 0.8,
        icons = {
          package_installed = '●',
          package_pending = '◒',
          package_uninstalled = '·',
        },
        keymaps = {
          toggle_server_expand = '<CR>',
          install_server = 'i',
          update_server = 'u',
          check_server_version = 'c',
          update_all_servers = 'U',
          check_outdated_servers = 'C',
          uninstall_server = 'X',
          cancel_installation = '<C-c>',
        },
      },
    },
  },
  {
    'nvimtools/none-ls.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'neovim/nvim-lspconfig',
    },
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      local null_ls = require('null-ls')
      null_ls.setup({
        sources = {
          -- https://github.com/nvimtools/none-ls.nvim/blob/main/doc/BUILTINS.md
          null_ls.builtins.diagnostics.actionlint.with({
            condition = function()
              return is_installed('actionlint')
            end,
          }),
          null_ls.builtins.diagnostics.fish.with({
            condition = function()
              return is_installed('fish')
            end,
          }),
          null_ls.builtins.diagnostics.hadolint.with({
            condition = function()
              return is_installed('hadolint')
            end,
          }),
        },
      })
    end,
  },
  {
    'neovim/nvim-lspconfig',
    cmd = { 'LspInfo', 'LspInstall', 'LspStart' },
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = {
      { 'saghen/blink.cmp' },
      {
        'mason-org/mason-lspconfig.nvim',
        dependencies = { 'mason-org/mason.nvim' },
        config = noop,
      },
      {
        'folke/lazydev.nvim',
        ft = 'lua',
        dependencies = { 'mason-org/mason-lspconfig.nvim' },
        opts = {
          library = {
            -- See the configuration section for more details
            -- Load luvit types when the `vim.uv` word is found
            { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
          },
        },
        -- config = noop,
      },
      {
        'b0o/schemastore.nvim',
        dependencies = { 'mason-org/mason-lspconfig.nvim' },
        config = noop,
      },
    },
    config = function()
      vim.lsp.set_log_level('ERROR')
      local mason = require('mason-registry')

      require('lspconfig.ui.windows').default_options.border = 'rounded'

      local capabilities = vim.tbl_deep_extend(
        'force',
        vim.lsp.protocol.make_client_capabilities(),
        require('blink.cmp').get_lsp_capabilities({}, false)
        -- require('cmp_nvim_lsp').default_capabilities()
      )

      -- if capabilities ~= nil then
      --   capabilities.textDocument.completion.completionItem = {
      --     documentationFormat = { 'markdown', 'plaintext' },
      --     snippetSupport = true,
      --     preselectSupport = true,
      --     insertReplaceSupport = true,
      --     labelDetailsSupport = true,
      --     deprecatedSupport = true,
      --     commitCharactersSupport = true,
      --     tagSupport = { valueSet = { 1 } },
      --     resolveSupport = {
      --       properties = {
      --         'documentation',
      --         'detail',
      --         'additionalTextEdits',
      --       },
      --     },
      --   }
      -- end

      local on_attach = function(client, bufnr)
        vim.api.nvim_buf_set_keymap(
          bufnr,
          'n',
          '<C-k>',
          '<cmd>lua vim.lsp.buf.signature_help({ border = "rounded" })<cr>',
          { noremap = true, silent = true, desc = 'Signature Help' }
        )
        vim.api.nvim_buf_set_keymap(
          bufnr,
          'n',
          'K',
          '<cmd>lua vim.lsp.buf.hover({ border = "rounded" })<cr>',
          { noremap = true, silent = true, desc = 'Hover' }
        )
        vim.api.nvim_buf_set_keymap(
          bufnr,
          'n',
          '<leader>r',
          -- ':Rename ',
          '<cmd>lua vim.lsp.buf.rename()<cr>',
          { noremap = true, silent = true, desc = 'Rename' }
        )

        vim.api.nvim_buf_set_keymap(
          bufnr,
          'n',
          '<leader>A',
          '<cmd>lua vim.lsp.buf.code_action()<cr>',
          { noremap = true, silent = true, desc = 'Code Action' }
        )

        vim.api.nvim_buf_set_keymap(
          bufnr,
          'x',
          '<leader>A',
          '<cmd>lua vim.lsp.buf.code_action()<cr>',
          { noremap = true, silent = true, desc = 'Code Action' }
        )

        vim.api.nvim_buf_set_keymap(
          bufnr,
          'n',
          '<C-Up>',
          '<cmd>lua vim.diagnostic.goto_prev()<cr>',
          { noremap = true, silent = true, desc = 'Previous Diagnostic' }
        )

        vim.api.nvim_buf_set_keymap(
          bufnr,
          'n',
          '<C-Down>',
          '<cmd>lua vim.diagnostic.goto_next()<cr>',
          { noremap = true, silent = true, desc = 'Next Diagnostic' }
        )

        require('lsp-fix').on_attach(client, bufnr)

        if client.name == 'ruff' then
          client.server_capabilities.hoverProvider = false
        end

        if client.name == 'cssls' then
          client.server_capabilities.diagnosticProvider = false
        end
      end

      vim.api.nvim_create_autocmd('LspAttach', {
        desc = 'LSP actions',
        callback = function(event)
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if not client then
            return
          end

          local bufnr = event.buf
          on_attach(client, bufnr)
        end,
      })

      local handlers = {
        ansiblels = ternary(is_installed('ansible-config'), function()
          vim.lsp.config('ansiblels', {
            capabilities = capabilities,
            settings = {
              ansible = {
                python = {
                  interpreterPath = 'python',
                },
                ansible = {
                  path = 'ansible',
                },
                executionEnvironment = {
                  enabled = false,
                },
                validation = {
                  enabled = true,
                  lint = {
                    enabled = is_installed('ansible-lint'),
                    path = 'ansible-lint',
                  },
                },
              },
            },
          })
        end),
        yamlls = function()
          vim.lsp.config('yamlls', {
            capabilities = capabilities,
            settings = {
              yaml = {
                schemas = vim.list_extend({
                  ['https://json.schemastore.org/lefthook.json'] = {
                    '/{.lefthook,lefthook,lefthook-local,.lefthook-local}.{yml,yaml,toml,json}',
                  },
                }, require('schemastore').yaml.schemas()),
                validate = { enable = true },
              },
            },
          })
        end,
        jsonls = function()
          vim.lsp.config('jsonls', {
            capabilities = capabilities,
            settings = {
              json = {
                schemas = require('schemastore').json.schemas(),
                validate = { enable = true },
              },
            },
          })
        end,
        -- lua_ls = function()
        --   require('lazydev').setup({
        --     library = {
        --       -- See the configuration section for more details
        --       -- Load luvit types when the `vim.uv` word is found
        --       { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
        --     },
        --   })
        -- end,
        pyright = function()
          vim.lsp.config('pyright', {
            capabilities = capabilities,
            fix = {
              function(bufnr, client)
                client.request_sync('workspace/executeCommand', {
                  command = 'pyright.organizeimports',
                  arguments = { vim.uri_from_bufnr(bufnr) },
                }, 3000, bufnr)
              end,
            },
          })
        end,
        ruff = function()
          vim.lsp.config('ruff', {
            capabilities = capabilities,
            fix = {
              function(bufnr, client)
                client.request_sync('workspace/executeCommand', {
                  command = 'ruff.applyOrganizeImports',
                  arguments = {
                    {
                      uri = vim.uri_from_bufnr(bufnr),
                      version = vim.lsp.util.buf_versions[bufnr],
                    },
                  },
                }, 3000, bufnr)
              end,
              function(bufnr, client)
                client.request_sync('workspace/executeCommand', {
                  command = 'ruff.applyAutofix',
                  arguments = {
                    {
                      uri = vim.uri_from_bufnr(bufnr),
                      version = vim.lsp.util.buf_versions[bufnr],
                    },
                  },
                }, 3000, bufnr)
              end,
            },
          })
        end,
        ts_ls = function()
          local hasVolar = mason.is_installed('vue-language-server')

          local tsWorkspaceConfiguration = {
            format = {
              indentSize = vim.o.shiftwidth,
              convertTabsToSpaces = vim.o.expandtab,
              tabSize = vim.o.tabstop,
              indentStyle = 'Smart',
              semicolons = 'remove',
              trimTrailingWhitespace = false,
              insertSpaceAfterCommaDelimiter = true,
              placeOpenBraceOnNewLineForControlBlocks = false,
              placeOpenBraceOnNewLineForFunctions = false,
              insertSpaceAfterConstructor = false,
              insertSpaceAfterFunctionKeywordForAnonymousFunctions = true,
              insertSpaceAfterKeywordsInControlFlowStatements = true,
              insertSpaceAfterOpeningAndBeforeClosingEmptyBraces = false,
              insertSpaceAfterOpeningAndBeforeClosingJsxExpressionBraces = false,
              insertSpaceAfterOpeningAndBeforeClosingNonemptyBraces = true,
              insertSpaceAfterOpeningAndBeforeClosingNonemptyBrackets = false,
              insertSpaceAfterOpeningAndBeforeClosingNonemptyParenthesis = false,
              insertSpaceAfterOpeningAndBeforeClosingTemplateStringBraces = false,
              insertSpaceAfterSemicolonInForStatements = true,
              insertSpaceAfterTypeAssertion = false,
              insertSpaceBeforeAndAfterBinaryOperators = true,
              insertSpaceBeforeFunctionParenthesis = false,
              insertSpaceBeforeTypeAnnotation = false,
            },
          }

          vim.lsp.config('ts_ls', {
            capabilities = capabilities,
            fix = {
              function(bufnr, client)
                client.request_sync('workspace/executeCommand', {
                  command = '_typescript.organizeImports',
                  arguments = { vim.api.nvim_buf_get_name(bufnr) },
                }, 3000, bufnr)
              end,
            },
            filetypes = concat({
              'typescript',
              'javascript',
              'javascriptreact',
              'typescriptreact',
            }, hasVolar and { 'vue' } or {}),
            init_options = vim.tbl_deep_extend('force', {
              hostInfo = 'neovim',
              preferences = {
                -- Supported values 'auto', 'double', 'single'
                quotePreference = 'auto',
                organizeImportsIgnoreCase = false,
                organizeImportsCollation = 'unicode',
                organizeImportsCollationLocale = 'en',
                organizeImportsNumericCollation = true,
                organizeImportsAccentCollation = false,
                organizeImportsCaseFirst = false,
                importModuleSpecifierPreference = 'relative',
                interactiveInlayHints = false,
              },
            }, hasVolar and {
              plugins = {
                {
                  name = '@vue/typescript-plugin',
                  location = vim.fn.expand(
                    '$MASON/packages/vue-language-server/node_modules/@vue/language-server'
                  ),
                  languages = { 'vue', 'typescript' },
                },
              },
            } or {}),
            settings = {
              typescript = tsWorkspaceConfiguration,
              javascript = tsWorkspaceConfiguration,
              completions = {
                completeFunctionCalls = true,
              },
              diagnostics = {
                ignoredCodes = { 80006 },
              },
            },
          })
        end,
        eslint = function()
          vim.lsp.config('eslint', {
            filetypes = {
              'astro',
              'javascript',
              'javascript.jsx',
              'javascriptreact',
              'json',
              'json5',
              'jsonc',
              'svelte',
              'toml',
              'typescript',
              'typescript.tsx',
              'typescriptreact',
              'vue',
              'yaml',
              'yaml.ansible',
            },
            capabilities = capabilities,
            settings = {
              workingDirectories = { mode = 'location' },
              experimental = {
                useFlatConfig = true,
              },
              useFlatConfig = true,
            },
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
      }

      vim.lsp.config('*', {
        capabilities = capabilities,
        -- root_markers = { '.git' },
      })

      for key, handler in pairs(handlers) do
        local value = handler()
        if value then
          vim.lsp.config(key, value)
        end
      end

      -- dockerls, terraformls, volar, taplo, glslls, bashls, cssls,
      require('mason-lspconfig').setup({
        automatic_enable = true,
        ensure_installed = {},
      })
    end,
  },
  {
    dir = '~/.vim/local/lsp-fix',
    dependencies = { 'neovim/nvim-lspconfig' },
    keys = {
      {
        '<leader>F',
        function()
          require('lsp-fix').fix()
        end,
        desc = 'Fix',
      },
    },
    config = function()
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
    end,
  },
  {
    'stevearc/conform.nvim',
    cmd = { 'ConformInfo' },
    dependencies = { 'neovim/nvim-lspconfig', 'mason-org/mason.nvim' },
    keys = {
      {
        '<leader>f',
        function()
          require('conform').format({ async = true, lsp_format = 'first' })
        end,
        desc = 'Format',
      },
    },
    config = function()
      require('conform').setup({
        formatters_by_ft = {
          javascript = { 'prettier' },
          json = { 'prettier' },
          json5 = { 'prettier' },
          jsonc = { 'prettier' },
          lua = { 'stylua' },
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
      })
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
      { 'rafamadriz/friendly-snippets' },
      {
        'L3MON4D3/LuaSnip',
        version = 'v2.*',
        build = 'make install_jsregexp',
        config = noop,
        dependencies = { { 'rafamadriz/friendly-snippets' } },
      },
    },
    config = function()
      local cmp = require('blink.cmp')
      local luasnip = require('luasnip')

      luasnip.config.setup()

      require('luasnip.loaders.from_vscode').lazy_load({
        exclude = { 'html', 'all' },
      })

      ---@module 'blink.cmp'
      ---@type blink.cmp.Config
      cmp.setup({
        snippets = { preset = 'luasnip' },
        keymap = {
          preset = 'none',
          ['<Up>'] = { 'select_prev', 'fallback' },
          ['<Down>'] = { 'select_next', 'fallback' },
          ['<CR>'] = { 'accept', 'fallback' },
          ['<Tab>'] = { 'select_next', 'snippet_forward', 'fallback' },
          ['<S-Tab>'] = { 'select_prev', 'snippet_backward', 'fallback' },
          ['<Esc>'] = { 'fallback' },
        },
        appearance = {
          use_nvim_cmp_as_default = true,
          -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
          -- Adjusts spacing to ensure icons are aligned
          nerd_font_variant = 'mono',
        },
        -- signature = { enabled = true },
        completion = {
          documentation = {
            auto_show = true,
            auto_show_delay_ms = 50,
            window = { border = 'rounded' },
          },
          trigger = {
            show_in_snippet = false,
          },
          list = {
            cycle = {
              from_bottom = true,
              from_top = true,
            },
            selection = {
              preselect = false,
              -- preselect = function(ctx)
              --   return not cmp.snippet_active()
              -- end,
              auto_insert = function(ctx)
                return not cmp.snippet_active()
              end,
            },
          },
          ghost_text = { enabled = true },
          menu = {
            border = 'rounded',
            winblend = 10,
            draw = {
              padding = { 1, 1 },
              columns = {
                { 'label' },
                { 'label_description' },
                { 'source_name' },
              },
              components = {
                source_name = {
                  text = function(ctx)
                    local source_name = ctx.source_name

                    if source_name == 'Snippets' then
                      return '∫'
                    end

                    if source_name == 'LSP' then
                      return '∴'
                    end

                    if source_name == 'Path' then
                      return '☇'
                    end

                    return source_name
                  end,
                },
                label_description = {
                  width = { fill = true, max = 60 },
                },
                label = {
                  width = { fill = true, max = 60 },
                  text = function(ctx)
                    return ctx.label .. ctx.label_detail
                  end,
                  highlight = function(ctx)
                    -- label and label details
                    local highlights = {
                      {
                        0,
                        #ctx.label,
                        group = ctx.deprecated and 'BlinkCmpLabelDeprecated'
                          or 'BlinkCmpLabel',
                      },
                    }
                    if ctx.label_detail then
                      table.insert(highlights, {
                        #ctx.label,
                        #ctx.label + #ctx.label_detail,
                        group = 'BlinkCmpLabelDetail',
                      })
                    end

                    return highlights
                  end,
                },
              },
            },
          },
        },
        sources = {
          default = { 'lsp', 'path', 'snippets', 'buffer' },
        },
        fuzzy = {
          sorts = {
            'exact',
            -- defaults
            'score',
            'sort_text',
          },
          implementation = 'prefer_rust_with_warning',
          -- implementation = 'lua',
        },
        cmdline = {
          enabled = true,
          keymap = {
            preset = 'none',
            ['<Up>'] = { 'select_prev', 'fallback' },
            ['<Down>'] = { 'select_next', 'fallback' },
            ['<CR>'] = { 'accept', 'fallback' },
            ['<Tab>'] = {
              function(cmp)
                if
                  not (vim.fn.getcmdtype() == ':' or vim.fn.getcmdtype() == '!')
                then
                  return true
                end
              end,
              'show_and_insert',
              'select_next',
            },
            ['<S-Tab>'] = {
              function(cmp)
                if
                  not (vim.fn.getcmdtype() == ':' or vim.fn.getcmdtype() == '!')
                then
                  return true
                end
              end,
              'show_and_insert',
              'select_prev',
            },
            ['<Esc>'] = { 'fallback' },
          },
          completion = {
            list = {
              cycle = {
                from_bottom = true,
                from_top = true,
              },
              selection = {
                preselect = false,
                auto_insert = true,
              },
            },
            menu = {
              draw = {
                padding = { 1, 1 },
                columns = {
                  { 'label' },
                },
              },
              auto_show = function(ctx)
                return vim.fn.getcmdtype() == ':' or vim.fn.getcmdtype() == '!'
              end,
            },
            ghost_text = {
              enabled = false,
            },
          },
        },
      })
    end,
  },
  {
    'Wansmer/treesj',
    keys = {
      { '<leader>j', '<cmd>TSJToggle<cr>', desc = 'Join Toggle' },
    },
    opts = { use_default_keymaps = false, max_join_length = 150 },
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
  },
  {
    'nvim-treesitter/nvim-treesitter',
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
    -- init = function(plugin)
    --   require('lazy.core.loader').add_to_rtp(plugin)
    --   require('nvim-treesitter.query_predicates')
    -- end,
    -- lazy = false,
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
        playground = {
          enable = true,
        },
        matchup = {
          enable = true,
          disable_virtual_text = true,
        },
        incremental_selection = {
          enable = false,
          keymaps = {
            init_selection = 'vv',
            node_incremental = '<Right>',
            scope_incremental = '<Up>',
            node_decremental = '<Left>',
          },
        },
        textobjects = {
          swap = {
            enable = false,
          },
          move = {
            enable = false,
          },
          select = {
            enable = false,
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
          'markdown',
          'markdown_inline',
          'mermaid',
          'perl',
          'prisma',
          'proto',
          'python',
          'r',
          'rust',
          'terraform',
          'toml',
          'tsx',
          'typescript',
          'vim',
          'vimdoc',
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
      -- vim.o.foldtext = "nvim_treesitter#foldtext()"
      vim.o.indentexpr = 'nvim_treesitter#indent()'
    end,
  },
  {
    'andymass/vim-matchup',
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'echasnovski/mini.base16',
    },
    event = { 'BufReadPre', 'BufNewFile' },
    init = function()
      -- vim.g.matchup_matchparen_offscreen =
      --   { method = 'popup', syntax_hl = 1, border = 'rounded', highlight = 'Normal' }
      vim.g.matchup_matchparen_offscreen = {}
      vim.g.matchup_matchparen_deferred = 1
      vim.g.matchup_matchparen_hi_surround_always = 0
      vim.g.matchup_mouse_enabled = 1
      vim.g.matchup_motion_override_Npercent = 0
      vim.g.matchup_matchpref = { html = { nolists = 1, tagnameonly = 1 } }
    end,
  },
  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    -- init = function(plugin)
    --   require('lazy.core.loader').add_to_rtp(plugin)
    -- end,
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
  },
  {
    'windwp/nvim-ts-autotag',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    opts = {
      enable = true,
      enable_rename = true,
      enable_close = true,
      enable_close_on_slash = true,
    },
    -- event = { 'VeryLazy' },
    ft = { 'html', 'vue' },
    event = { 'BufReadPre', 'BufNewFile' },
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
      require('Comment').setup({
        toggler = {
          line = '<leader>cc',
          block = '<leader>cC',
        },
        opleader = {
          line = '<leader>c',
          block = '<leader>C',
        },
        extra = {
          above = '<leader>cO',
          below = '<leader>co',
          eol = '<leader>cA',
        },
        mappings = {
          basic = true,
          extra = true,
        },
        pre_hook = require(
          'ts_context_commentstring.integrations.comment_nvim'
        ).create_pre_hook(),
      })
    end,
  },
  {
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    config = function()
      require('nvim-autopairs').setup({
        check_ts = true,
        enable_afterquote = true,
        enable_moveright = true,
        enable_check_bracket_line = true,
        disable_filetype = { 'TelescopePrompt', 'mason', 'lazy', 'vim' },
      })

      -- local cmp_autopairs = require('nvim-autopairs.completion.cmp')
      -- local cmp = require('cmp')
      -- cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done())
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
          on_yank = true,
          timer = 200,
        },
        preserve_cursor_position = {
          enabled = true,
        },
      })
    end,
  },
  {
    'jiaoshijie/undotree',
    dependencies = 'nvim-lua/plenary.nvim',
    opts = {
      position = 'right',
      float_diff = true,
      window = {
        winblend = 10,
      },
    },
    keys = {
      {
        '<leader>u',
        "<cmd>lua require('undotree').toggle()<cr>",
        desc = 'Undo Tree',
      },
    },
  },
  {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.8',
    dependencies = {
      'nvim-lua/plenary.nvim',
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make',
        cond = function()
          return vim.fn.executable('make') == 1
        end,
      },
      'nvim-treesitter/nvim-treesitter',
      'neovim/nvim-lspconfig',
      'gbprod/yanky.nvim',
    },
    cmd = { 'Telescope' },
    keys = {
      {
        '<leader>Tt',
        '<cmd>Telescope treesitter<cr>',
        desc = 'Treesitter Symbols',
      },
      {
        '<leader>Td',
        '<cmd>Telescope lsp_document_symbols<cr>',
        desc = 'Document Symbols',
      },
      {
        '<leader>Tw',
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
    config = function()
      local telescope = require('telescope')

      telescope.setup({
        defaults = {
          results_title = '',
          prompt_title = '',
          layout_strategy = 'horizontal',
          mappings = {},
          winblend = 10,
          prompt_prefix = ' ',
          selection_caret = '  ',
          entry_prefix = '  ',
          initial_mode = 'insert',
          path_display = { 'truncate' },
          set_env = { ['COLORTERM'] = 'truecolor' },
          vimgrep_arguments = {
            'rg',
            '--color=never',
            '--no-heading',
            '--with-filename',
            '--line-number',
            '--column',
            '--smart-case',
            '--hidden',
            '--glob',
            '!.git',
          },
        },
        pickers = {
          find_files = {
            find_command = {
              'rg',
              '--color=never',
              '--no-heading',
              '-L',
              '--files',
              '--hidden',
              '--glob',
              '!.git',
            },
          },
        },
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
      telescope.load_extension('yank_history')
    end,
  },
  {
    'echasnovski/mini.ai',
    version = '*',
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = {
      'nvim-treesitter/nvim-treesitter-textobjects',
    },
    config = function()
      local gen_spec = require('mini.ai').gen_spec

      -- TODO: add more queries
      require('mini.ai').setup({
        n_lines = 1024,
        custom_textobjects = {
          o = gen_spec.treesitter({
            a = { '@block.outer', '@conditional.outer', '@loop.outer' },
            i = { '@block.inner', '@conditional.inner', '@loop.inner' },
          }, {}),
          f = gen_spec.treesitter(
            { a = '@function.outer', i = '@function.inner' },
            {}
          ),
          c = gen_spec.treesitter(
            { a = '@class.outer', i = '@class.inner' },
            {}
          ),
          t = { '<([%p%w]-)%f[^<%w][^<>]->.-</%1>', '^<.->().*()</[^/]->$' },
        },
        mappings = {
          around = 'a',
          inside = 'i',
          around_next = 'an',
          around_last = 'aN',
          inside_next = 'in',
          inside_last = 'iN',
          goto_left = '',
          goto_right = '',
        },
      })
    end,
  },
  {
    'echasnovski/mini.surround',
    -- event = 'InsertEnter',
    -- event = { 'VeryLazy' },
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = {
      'nvim-treesitter/nvim-treesitter-textobjects',
    },
    opts = {
      mappings = {
        add = '<leader>sa', -- Add surrounding in Normal and Visual modes
        delete = '<leader>sd', -- Delete surrounding
        find = '<leader>sf', -- Find surrounding (to the right)
        find_left = '<leader>sF', -- Find surrounding (to the left)
        highlight = '', -- Highlight surrounding
        replace = '<leader>sr', -- Replace surrounding
        update_n_lines = '<leader>sn', -- Update `n_lines`
        suffix_last = '', -- Suffix to search with "prev" method
        suffix_next = '', -- Suffix to search with "next" method
      },
      n_lines = 500,
    },
    config = function(_, opts)
      -- opts.custom_surroundings = nil
      require('mini.surround').setup(opts)
    end,
  },
  {
    'folke/flash.nvim',
    event = 'VeryLazy',
    ---@type Flash.Config
    opts = {
      search = {
        exclude = {
          'notify',
          'cmp_menu',
          'noice',
          'flash_prompt',
          function(win)
            -- exclude non-focusable windows
            return not vim.api.nvim_win_get_config(win).focusable
          end,
        },
      },
      modes = {
        search = {
          enabled = true,
        },
        char = {
          enabled = false,
        },
        prompt = {
          enabled = false,
        },
      },
      highlight = {
        backdrop = false,
        matches = true,
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
      {
        'vv',
        mode = { 'n', 'x', 'o' },
        function()
          require('flash').treesitter()
        end,
        desc = 'Treesitter Visual',
      },
    },
  },
  -- {
  --   'echasnovski/mini.jump2d',
  --   dependencies = { 'echasnovski/mini.base16' },
  --  keeys = { '<CR>', desc = 'Jump' },
  --   config = function()
  --     require('mini.jump2d').setup({
  --       view = {
  --         dim = false,
  --         n_steps_ahead = 0,
  --       },
  --     })
  --   end,
  -- },
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
    version = '*',
    keys = { { '<leader>l', mode = { 'n', 'x' }, desc = 'Align' } },
    config = function()
      require('mini.align').setup({
        mappings = {
          start = '',
          start_with_preview = '<leader>l',
        },
        --  ['s'] = --<function: enter split pattern>,
        --  ['j'] = --<function: choose justify side>,
        --  ['m'] = --<function: enter merge delimiter>,
        --
        --  -- Modifiers adding pre-steps
        --  ['f'] = --<function: filter parts by entering Lua expression>,
        --  ['i'] = --<function: ignore some split matches>,
        --  ['p'] = --<function: pair parts>,
        --  ['t'] = --<function: trim parts>,
        --
        --  -- Delete some last pre-step
        --  ['<BS>'] = --<function: delete some last pre-step>,
        --
        --  -- Special configurations for common splits
        --  ['='] = --<function: enhanced setup for '='>,
        --  [','] = --<function: enhanced setup for ','>,
        --  [' '] = --<function: enhanced setup for ' '>,
      })
    end,
  },
  {
    'folke/which-key.nvim',
    cmd = 'WhichKey',
    event = 'VeryLazy',
    keys = {
      {
        '<leader>?',
        function()
          require('which-key').show({ global = true })
        end,
        desc = 'Which Key',
      },
    },
    opts = {
      ---@type false | "classic" | "modern" | "helix"
      preset = 'classic',
      -- Delay before showing the popup. Can be a number or a function that returns a number.
      ---@type number | fun(ctx: { keys: string, mode: string, plugin?: string }):number
      delay = function(ctx)
        return ctx.plugin and 0 or 200
      end,
      filter = function( --[[ mapping ]])
        -- example to exclude mappings without a description
        -- return mapping.desc and mapping.desc ~= ""
        return true
      end,
      --- You can add any mappings here, or use `require('which-key').add()` later
      spec = {},
      -- show a warning when issues were detected with your mappings
      notify = true,
      -- Start hidden and wait for a key to be pressed before showing the popup
      -- Only used by enabled xo mapping modes.
      ---@param ctx { mode: string, operator: string }
      defer = function(ctx)
        return ctx.mode == 'V' or ctx.mode == '<C-V>'
      end,
      plugins = {
        marks = true, -- shows a list of your marks on ' and `
        registers = true, -- shows your registers on " in NORMAL or <C-r> in INSERT mode
        -- the presets plugin, adds help for a bunch of default keybindings in Neovim
        -- No actual key bindings are created
        spelling = {
          enabled = false,
        },
        presets = {
          operators = true, -- adds help for operators like d, y, ...
          motions = true, -- adds help for motions
          text_objects = true, -- help for text objects triggered after entering an operator
          windows = true, -- default bindings on <c-w>
          nav = true, -- misc bindings to work with windows
          z = true, -- bindings for folds, spelling and others prefixed with z
          g = true, -- bindings for prefixed with g
        },
      },
      win = {
        -- don't allow the popup to overlap with the cursor
        no_overlap = true,
        -- width = 1,
        -- height = { min = 4, max = 25 },
        -- col = 0,
        -- row = math.huge,
        border = 'rounded',
        padding = { 2, 2 }, -- extra window padding [top/bottom, right/left]
        title = false,
        title_pos = 'center',
        zindex = 1000,
        -- Additional vim.wo and vim.bo options
        bo = {},
        wo = {
          winblend = 10, -- value between 0-100 0 for fully opaque and 100 for fully transparent
        },
      },
      layout = {
        width = { min = 10, max = 30 }, -- min and max width of the columns
        spacing = 2, -- spacing between columns
        align = 'center', -- align columns left, center or right
      },
      keys = {
        scroll_down = '<c-d>', -- binding to scroll down inside the popup
        scroll_up = '<c-u>', -- binding to scroll up inside the popup
      },
      --- Mappings are sorted using configured sorters and natural sort of the keys
      --- Available sorters:
      --- * local: buffer-local mappings first
      --- * order: order of the items (Used by plugins like marks / registers)
      --- * group: groups last
      --- * alphanum: alpha-numerical first
      --- * mod: special modifier keys last
      --- * manual: the order the mappings were added
      --- * case: lower-case first
      sort = { 'local', 'order', 'group', 'alphanum', 'mod' },
      ---@type number|fun(node):boolean?
      expand = 0, -- expand groups when <= n mappings
      -- expand = function(node)
      --   return not node.desc -- expand all nodes without a description
      -- end,
      -- Functions/Lua Patterns for formatting the labels
      ---@type table<string, ({[1]:string, [2]:string}|fun(str:string):string)[]>
      replace = {
        key = {
          function(key)
            return require('which-key.view').format(key)
          end,
          -- { "<Space>", "SPC" },
        },
        desc = {
          { '<Plug>%(?(.*)%)?', '%1' },
          { '^%+', '' },
          { '<[cC]md>', '' },
          { '<[cC][rR]>', '' },
          { '<[sS]ilent>', '' },
          { '^lua%s+', '' },
          { '^call%s+', '' },
          { '^:%s*', '' },
        },
      },
      icons = {
        breadcrumb = '»', -- symbol used in the command line area that shows your active key combo
        separator = '➜', -- symbol used between a key and it's label
        group = '+', -- symbol prepended to a group
        ellipsis = '…',
        -- set to false to disable all mapping icons,
        -- both those explicitely added in a mapping
        -- and those from rules
        mappings = false,
        --- See `lua/which-key/icons.lua` for more details
        --- Set to `false` to disable keymap icons from rules
        rules = {},
        -- use the highlights from mini.icons
        -- When `false`, it will use `WhichKeyIcon` instead
        colors = true,
        -- used by key format
        keys = {
          Up = '<Up>',
          Down = '<Down>',
          Left = '<Left>',
          Right = '<Right>',
          C = '',
          M = '',
          D = '',
          S = '',
          CR = '<CR>',
          Esc = '<Esc>',
          ScrollWheelDown = ' ',
          ScrollWheelUp = ' ',
          NL = ' ',
          BS = '<Backspace>',
          Space = '<Space>',
          Tab = '<Tab>',
          F1 = '<F1>',
          F2 = '<F2>',
          F3 = '<F3>',
          F4 = '<F4>',
          F5 = '<F5>',
          F6 = '<F6>',
          F7 = '<F7>',
          F8 = '<F8>',
          F9 = '<F9>',
          F10 = '<F10>',
          F11 = '<F11>',
          F12 = '<F12>',
        },
      },
      show_help = true, -- show a help message in the command line for using WhichKey
      show_keys = true, -- show the currently pressed key and its label as a message in the command line
      -- Which-key automatically sets up triggers for your mappings.
      -- But you can disable this and setup the triggers yourself.
      -- Be aware, that triggers are not needed for visual and operator pending mode.
      -- triggers = true, -- automatically setup triggers
      disable = {
        -- disable WhichKey for certain buf types and file types.
        ft = { 'mason', 'lazy', 'TelescopePrompt' },
        bt = {
          'help',
          'nofile',
          'nowrite',
          'quickfix',
          'terminal',
          'prompt',
        },
        -- -- disable a trigger for a certain context by returning true
        -- ---@type fun(ctx: { keys: string, mode: string, plugin?: string }):boolean?
        -- trigger = function(ctx)
        --   return false
        -- end,
      },
      debug = false, -- enable wk.log in the current directory
    },
    config = function(_, opts)
      local wk = require('which-key')
      wk.setup(opts)

      wk.add({
        { '<leader>c', desc = 'Comment' },
        { '<leader>T', desc = 'Tags' },
        { '<leader>n', desc = 'Case', mode = { 'n', 'x' } },
        { '<leader>a', desc = 'Avante', mode = { 'n', 'x' } },
        { '<leader>s', desc = 'Surround', mode = { 'n', 'x' } },
        { '<leader>sa', desc = 'Add surrounding', mode = { 'n', 'x' } },
        { '<leader>sd', desc = 'Delete surrounding', mode = 'n' },
        { '<leader>sf', desc = 'Find surrounding', mode = 'n' },
        { '<leader>sF', desc = 'Find surrounding', mode = 'n' },
        { '<leader>sr', desc = 'Replace surrounding', mode = 'n' },
        { 'n', desc = 'Next', mode = { 'n', 'x' } },
        { 'N', desc = 'Previous', mode = { 'n', 'x' } },
        { 'n', desc = 'Down', mode = { 'n', 'x' } },
        { 'N', desc = 'Up', mode = { 'n', 'x' } },
      })

      local objects = {
        { ' ', desc = 'whitespace' },
        { '"', desc = '" string' },
        { "'", desc = "' string" },
        { '(', desc = '() block' },
        { ')', desc = '() block with ws' },
        { '<', desc = '<> block' },
        { '>', desc = '<> block with ws' },
        { '?', desc = 'user prompt' },
        { 'U', desc = 'use/call without dot' },
        { '[', desc = '[] block' },
        { ']', desc = '[] block with ws' },
        { '_', desc = 'underscore' },
        { '`', desc = '` string' },
        { 'a', desc = 'argument' },
        { 'b', desc = ')]} block' },
        { 'c', desc = 'class' },
        { 'd', desc = 'digit(s)' },
        { 'e', desc = 'CamelCase / snake_case' },
        { 'f', desc = 'function' },
        { 'g', desc = 'entire file' },
        { 'i', desc = 'indent' },
        { 'o', desc = 'block, conditional, loop' },
        { 'q', desc = 'quote `"\'' },
        { 't', desc = 'tag' },
        { 'u', desc = 'use/call' },
        { '{', desc = '{} block' },
        { '}', desc = '{} with ws' },
      }

      local ret = { mode = { 'o', 'x' } }
      ---@type table<string, string>
      local mappings = vim.tbl_extend('force', {}, {
        around = 'a',
        inside = 'i',
        around_last = 'aN',
        around_next = 'an',
        inside_last = 'iN',
        inside_next = 'in',
      }, opts.mappings or {})
      mappings.goto_left = nil
      mappings.goto_right = nil

      for name, prefix in pairs(mappings) do
        name = name:gsub('^around_', ''):gsub('^inside_', '')
        ret[#ret + 1] = { prefix, group = name }
        for _, obj in ipairs(objects) do
          local desc = obj.desc
          if prefix:sub(1, 1) == 'i' then
            desc = desc:gsub(' with ws', '')
          end
          ret[#ret + 1] = { prefix .. obj[1], desc = obj.desc }
        end
      end

      wk.add(ret, { notify = false })
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
      { '<Left>', '<Plug>(CybuPrev)', desc = 'Previous Buffer' },
      { '<Right>', '<Plug>(CybuNext)', desc = 'Next Buffer' },
      -- { '<C-Left>', '<Plug>(CybuLastusedPrev)', desc = 'Previous Buffer' },
      -- { '<C-Right>', '<Plug>(CybuLastusedNext)', desc = 'Next Buffer' },
      -- vim.cmd [[nnoremap <leader><leader> :]]
      {
        '<leader><leader>',
        '<Plug>(CybuLastusedNext)',
        desc = 'Switch Buffer',
      },
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
        behavior = { -- set behavior for different modes
          mode = {
            default = {
              switch = 'immediate', -- immediate, on_close
              view = 'rolling', -- paging, rolling
            },
            last_used = {
              switch = 'immediate', -- immediate, on_close
              view = 'rolling', -- paging, rolling
            },
            auto = {
              view = 'rolling',
            },
          },
          show_on_autocmd = false, -- event to trigger cybu (eg. "BufEnter")
        },
        display_time = 500, -- time the cybu window is displayed
        exclude = { -- filetypes, cybu will not be active
          'cmp_menu',
          'flash_prompt',
          'fugitive',
          'neo-tree',
          'noice',
          'notify',
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
    'folke/zen-mode.nvim',
    keys = {
      {
        '<leader>z',
        function()
          require('zen-mode').toggle({})
        end,
        desc = 'Zen Mode',
      },
    },
    opts = {
      window = {
        backdrop = 1,
        width = 1,
        height = 1,
      },
      options = {
        signcolumn = 'no',
        number = false,
        relativenumber = false,
        cursorline = false,
        cursorcolumn = false,
        foldcolumn = '0',
        list = false,
      },
      plugins = {
        options = {
          enabled = true,
          ruler = false,
          showcmd = false,
          laststatus = 0,
          cmdheight = 0,
        },
        twilight = { enabled = false },
        gitsigns = { enabled = false },
        tmux = { enabled = false },
        kitty = {
          enabled = false,
        },
        alacritty = {
          enabled = false,
        },
        wezterm = {
          enabled = false,
        },
      },

      on_open = function()
        require('ibl').update({ enabled = false })
      end,
      on_close = function()
        require('ibl').update({ enabled = true })
      end,
    },
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
        function()
          require('gtd').exec({ command = 'edit' })
        end,
      },
    },
    config = function()
      require('gtd').setup({})
    end,
  },
  {
    'johmsalas/text-case.nvim',
    dependencies = { 'nvim-telescope/telescope.nvim' },
    event = { 'BufReadPre', 'BufNewFile' },
    --     cmd = {
    --   -- NOTE: The Subs command name can be customized via the option "substitude_command_name"
    --   "Subs",
    --   "TextCaseOpenTelescope",
    --   "TextCaseOpenTelescopeQuickChange",
    --   "TextCaseOpenTelescopeLSPChange",
    --   "TextCaseStartReplacingCommand",
    -- },
    config = function()
      require('textcase').setup({
        default_keymappings_enabled = true,
        prefix = '<leader>n',
      })
    end,
  },
  {
    'aaronik/treewalker.nvim',
    keys = {
      -- Movement
      {
        '<C-S-k>',
        '<cmd>Treewalker Up<cr>',
        mode = { 'n', 'v' },
        desc = 'Move up',
        silent = true,
      },
      {
        '<C-S-j>',
        '<cmd>Treewalker Down<cr>',
        mode = { 'n', 'v' },
        desc = 'Move down',
        silent = true,
      },
      {
        '<C-S-l>',
        '<cmd>Treewalker Right<cr>',
        mode = { 'n', 'v' },
        desc = 'Move right',
        silent = true,
      },
      {
        '<C-S-h>',
        '<cmd>Treewalker Left<cr>',
        mode = { 'n', 'v' },
        desc = 'Move left',
        silent = true,
      },
      -- Swapping
      -- { '<C-S-j>', '<cmd>Treewalker SwapDown<cr>', mode = 'n', desc = 'Swap down', silent = true },
      -- { '<C-S-k>', '<cmd>Treewalker SwapUp<cr>', mode = 'n', desc = 'Swap up', silent = true },
      -- { '<C-S-l>', '<cmd>Treewalker SwapRight<CR>', mode = 'n', desc = 'Swap right', silent = true },
      -- { '<C-S-h>', '<cmd>Treewalker SwapLeft<CR>', mode = 'n', desc = 'Swap left', silent = true },
    },
    opts = {
      highlight = false,
      highlight_duration = 250,
      highlight_group = 'CursorLine',
    },
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
