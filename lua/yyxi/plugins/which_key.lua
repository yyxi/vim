local M = {}

function M.setup()
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

return M
