local M = {}

function M.setup()
  local opts = {
    mappings = {
      add = '<leader>sa', -- Add surrounding in Normal and Visual modes
      delete = '<leader>sd', -- Delete surrounding
      find = '<leader>sf', -- Find surrounding (to the right)
      find_left = '<leader>sF', -- Find surrounding (to the left)
      highlight = '', -- Highlight surrounding
      replace = '<leader>sr', -- Replace surrounding
      update_n_lines = '<leader>sn', -- Update `n_lines`
      suffix_last = '', -- Suffix to search with "prev" method
      suffix_next = '', -- Suffix to search with "next" method
    },
    n_lines = 500,
  }

  -- opts.custom_surroundings = nil
  require('mini.surround').setup(opts)
end

return M
