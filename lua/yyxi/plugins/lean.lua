local M = {}

function M.setup()
  ---@type lean.Config
  local opts = { -- see below for full configuration options
    mappings = false,
    infoview = {
      autoopen = false,
    },
    progress_bars = {
      enable = false,
    },
    stderr = {
      enable = false,
    },
  }

  require('lean').setup(opts)
end

return M
