local M = {}

function M.setup()
  local opts = { use_default_keymaps = false, max_join_length = 150 }

  require('treesj').setup(opts)
end

return M
