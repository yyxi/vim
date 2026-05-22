local M = {}

function M.setup()
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

return M
