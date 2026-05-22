local M = {}

function M.setup()
  ---@type Flash.Config
  local opts = {
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
  }

  require('flash').setup(opts)
end

return M
