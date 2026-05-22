local M = {}

function M.setup()
  ---@type nvim-ts-autotag.PluginSetup
  local opts = {
    opts = {
      enable_rename = true,
      enable_close = true,
      enable_close_on_slash = true,
    },
  }

  require('nvim-ts-autotag').setup(opts)
end

return M
