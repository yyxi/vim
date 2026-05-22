local M = {}

function M.setup()
  require('mini.align').setup({
    mappings = {
      start = '',
      start_with_preview = '<leader>a',
    },
  })
end

return M
