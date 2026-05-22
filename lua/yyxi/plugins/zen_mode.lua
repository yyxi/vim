local M = {}

function M.setup()
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
