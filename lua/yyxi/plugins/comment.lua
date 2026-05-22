local M = {}

function M.setup()
  -- Comment.nvim's public type marks defaulted fields as required.
  ---@diagnostic disable: missing-fields
  ---@type CommentConfig
  local opts = {
    toggler = {
      line = '<leader>cc',
      block = '<leader>cC',
    },
    opleader = {
      line = '<leader>c',
      block = '<leader>C',
    },
    extra = {
      above = '<leader>cO',
      below = '<leader>co',
      eol = '<leader>cA',
    },
    mappings = {
      basic = true,
      extra = true,
    },
    pre_hook = require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook(),
  }
  ---@diagnostic enable: missing-fields

  require('Comment').setup(opts)
end

return M
