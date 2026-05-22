local M = {}

function M.setup()
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
  }

  require('cybu').setup(opts)
  -- vim.keymap.set('n', 'K', '<Plug>(CybuPrev)')
  -- vim.keymap.set('n', 'J', '<Plug>(CybuNext)')
end

return M
