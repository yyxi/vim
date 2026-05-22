local M = {}

function M.setup()
  require('textcase').setup({
    default_keymappings_enabled = true,
    prefix = '<leader>n',
  })
end

return M
