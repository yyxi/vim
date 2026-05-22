local M = {}

function M.setup()
  ---@type lazydev.Config
  local opts = {
    library = {
      { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
    },
  }

  require('lazydev').setup(opts)
end

return M
