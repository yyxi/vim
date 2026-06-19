local M = {}

local exclusions = require('yyxi.utilities.exclusions')

local PRIVILEGED_BUFFER_NAME_PREFIX = 'sudo://'
local LUALINE_FILENAME_SHORTING_TARGET = 40
local LUALINE_FILENAME_SYMBOLS = {
  unnamed = '[No Name]',
  modified = '[+]',
  readonly = '[-]',
}

local function is_privileged_buffer_name(name)
  return vim.startswith(name or '', PRIVILEGED_BUFFER_NAME_PREFIX)
end

-- Mirror the built-in lualine filename shortening logic closely enough to keep the
-- current statusline shape. The built-in component treats 'sudo://' names as URIs,
-- so it cannot derive the relative path we want for managed privileged buffers.
local function shorten_path(path, sep, max_len)
  local len = #path
  if len <= max_len then return path end

  local segments = vim.split(path, sep)
  for idx = 1, #segments - 1 do
    if len <= max_len then break end

    local segment = segments[idx]
    local shortened = segment:sub(1, vim.startswith(segment, '.') and 2 or 1)
    segments[idx] = shortened
    len = len - (#segment - #shortened)
  end

  return table.concat(segments, sep)
end

local function lualine_filename_display()
  local name = vim.api.nvim_buf_get_name(0)
  local display_path

  if is_privileged_buffer_name(name) then
    local canonical_path = vim.b.privileged_editing_path
      or name:sub(#PRIVILEGED_BUFFER_NAME_PREFIX + 1)
    display_path = vim.fn.fnamemodify(canonical_path, ':~:.')
  else
    display_path = vim.fn.expand('%:~:.')
  end

  if display_path == '' then display_path = LUALINE_FILENAME_SYMBOLS.unnamed end

  local path_separator = package.config:sub(1, 1)
  local windwidth = vim.go.laststatus == 3 and vim.go.columns or vim.fn.winwidth(0)
  local estimated_space_available = windwidth - LUALINE_FILENAME_SHORTING_TARGET
  display_path = shorten_path(display_path, path_separator, estimated_space_available)

  local symbols = {}
  if vim.bo.modified then table.insert(symbols, LUALINE_FILENAME_SYMBOLS.modified) end
  if vim.bo.modifiable == false or vim.bo.readonly == true then
    table.insert(symbols, LUALINE_FILENAME_SYMBOLS.readonly)
  end

  return display_path .. (#symbols > 0 and ' ' .. table.concat(symbols, '') or '')
end

local function lualine_filename_color()
  if not is_privileged_buffer_name(vim.api.nvim_buf_get_name(0)) then return nil end

  -- Reuse lualine's own visual-mode "a" highlight instead of hardcoding red.
  -- With the default auto theme, that color ultimately comes from the current
  -- colorscheme's first available foreground among Special, Boolean, or Constant,
  -- then lualine applies its brightness/contrast adjustments when building the theme.
  local ok, highlight = pcall(require('lualine.highlight').get_lualine_hl, 'lualine_a_visual')
  if ok and type(highlight) == 'table' and highlight.bg then
    return {
      fg = highlight.fg,
      bg = highlight.bg,
      gui = 'bold',
    }
  end

  return 'ErrorMsg'
end

function M.cybu()
  ---@type CybuConfig
  local opts = {
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
    exclude = exclusions.cybu_excluded_filetypes(),
    filter = {
      unlisted = true, -- filter & fallback for unlisted buffers
    },
  }

  require('cybu').setup(opts)
  -- vim.keymap.set('n', 'K', '<Plug>(CybuPrev)')
  -- vim.keymap.set('n', 'J', '<Plug>(CybuNext)')
end

function M.flash()
  ---@type Flash.Config
  local opts = {
    search = {
      exclude = exclusions.flash_search_exclusions(),
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
  }

  require('flash').setup(opts)
end

function M.indent_blankline()
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

function M.lualine()
  local opts = {
    extensions = { 'lazy', 'man' },
    options = {
      always_divide_middle = true,
      component_separators = '',
      globalstatus = true,
      icons_enabled = false,
      section_separators = '',
      -- theme = 'gruvbox',
      disabled_filetypes = exclusions.lualine_disabled_filetypes(),
    },

    sections = {
      lualine_a = { 'mode' },
      lualine_b = { 'branch' },
      lualine_c = {
        {
          lualine_filename_display,
          color = lualine_filename_color,
        },
      },
      lualine_x = { 'encoding', 'fileformat', 'filetype' },
      lualine_y = { 'progress' },
      lualine_z = { 'location' },
    },
    inactive_sections = {
      lualine_a = {},
      lualine_b = {},
      lualine_c = {
        {
          lualine_filename_display,
          color = lualine_filename_color,
        },
      },
      lualine_x = { 'location' },
      lualine_y = {},
      lualine_z = {},
    },
  }

  require('lualine').setup(opts)
end

function M.snacks()
  ---@type snacks.Config
  local opts = {
    input = {
      enabled = true,
      icon = '',
    },
    notifier = { enabled = false },
    bigfile = { enabled = true },
    dashboard = { enabled = false },
    explorer = { enabled = false },
    indent = { enabled = false },
    picker = { enabled = false },
    quickfile = { enabled = true },
    scope = { enabled = false },
    scroll = { enabled = false },
    statuscolumn = { enabled = false },
    words = { enabled = false },
  }

  require('snacks').setup(opts)
end

function M.telescope()
  local telescope = require('telescope')

  telescope.setup({
    defaults = {
      results_title = '',
      prompt_title = '',
      dynamic_preview_title = false,
      layout_strategy = 'flex',
      mappings = {},
      winblend = 10,
      prompt_prefix = ' ',
      selection_caret = '  ',
      entry_prefix = '  ',
      initial_mode = 'insert',
      -- path_display = { 'truncate' },
      path_display = {
        'filename_first',
      },
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
        '--trim',
        '--glob',
        '!.git',
      },
      preview = {
        filesize_limit = 1, -- MB
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
      buffers = {
        select_current = true,
        sort_mru = true,
      },
    },
    extensions = {
      ['ui-select'] = {
        layout_strategy = 'flex',
      },
      fzf = {
        fuzzy = true, -- false will only do exact matching
        -- Keep the native sorter as the global Telescope default for non-FFF
        -- pickers and for builtin fallback paths when the FFF backend is unavailable.
        override_generic_sorter = true, -- override the generic sorter
        override_file_sorter = true, -- override the file sorter
        case_mode = 'smart_case', -- or "ignore_case" or "respect_case"
      },
    },
  })

  pcall(telescope.load_extension, 'fzf')
  telescope.load_extension('yank_history')
  telescope.load_extension('ui-select')
end

function M.which_key()
  ---@type wk.Opts
  local opts = {
    ---@type false | "classic" | "modern" | "helix"
    preset = 'classic',
    -- Delay before showing the popup. Can be a number or a function that returns a number.
    ---@type number | fun(ctx: { keys: string, mode: string, plugin?: string }):number
    delay = function(ctx) return ctx.plugin and 0 or 200 end,
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
    defer = function(ctx) return ctx.mode == 'V' or ctx.mode == '<C-V>' end,
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
        function(key) return require('which-key.view').format(key) end,
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
      ft = exclusions.which_key_disabled_filetypes(),
      bt = exclusions.non_editing_buftypes(),
      -- -- disable a trigger for a certain context by returning true
      -- ---@type fun(ctx: { keys: string, mode: string, plugin?: string }):boolean?
      -- trigger = function(ctx)
      --   return false
      -- end,
    },
    debug = false, -- enable wk.log in the current directory
  }

  local wk = require('which-key')
  wk.setup(opts)

  wk.add({
    { '<leader>c', desc = 'Comment' },
    { '<leader>T', desc = 'Tags' },
    { '<leader>n', desc = 'Case', mode = { 'n', 'x' } },
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
    { 'C', desc = 'class' },
    { 'c', desc = 'call' },
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

  ---@type wk.Spec
  local ret = { mode = { 'o', 'x' } }
  ---@type table<string, string>
  local mappings = vim.tbl_extend('force', {}, {
    around = 'a',
    inside = 'i',
    around_next = 'an',
    around_last = 'aN',
    inside_next = 'in',
    inside_last = 'iN',
  })
  mappings.goto_left = nil
  mappings.goto_right = nil

  for name, prefix in pairs(mappings) do
    name = name:gsub('^around_', ''):gsub('^inside_', '')
    ret[#ret + 1] = { prefix, group = name }
    for _, obj in ipairs(objects) do
      local desc = obj.desc
      if prefix:sub(1, 1) == 'i' then desc = desc:gsub(' with ws', '') end
      ret[#ret + 1] = { prefix .. obj[1], desc = obj.desc }
    end
  end

  wk.add(ret, { notify = false })
end

function M.zen_mode()
  ---@type ZenOptions
  local opts = {
    window = {
      backdrop = 1,
      width = 100,
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

    on_open = function() require('ibl').update({ enabled = false }) end,
    on_close = function() require('ibl').update({ enabled = true }) end,
  }

  require('zen-mode').setup(opts)
end

return M
