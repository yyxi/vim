local M = {}

function M.setup()
  ---@type MasonSettings
  local opts = {
    PATH = 'append',
    log_level = vim.log.levels.WARN,
    max_concurrent_installers = 10,
    pip = {
      upgrade_pip = false,
    },
    ui = {
      border = 'rounded',
      width = 0.8,
      height = 0.8,
      icons = {
        package_installed = '●',
        package_pending = '◒',
        package_uninstalled = '·',
      },
      keymaps = {
        toggle_server_expand = '<CR>',
        install_server = 'i',
        update_server = 'u',
        check_server_version = 'c',
        update_all_servers = 'U',
        check_outdated_servers = 'C',
        uninstall_server = 'X',
        cancel_installation = '<C-c>',
      },
    },
  }

  require('mason').setup(opts)
end

return M
