local M = {}

function M.setup()
  local opts = {
    extensions = { 'mason', 'lazy', 'man' },
    options = {
      always_divide_middle = true,
      component_separators = '',
      globalstatus = true,
      icons_enabled = false,
      section_separators = '',
      -- theme = 'gruvbox',
      disabled_filetypes = {
        -- TelescopePrompt = {},
        -- mason = {},
        -- lazy = {},
        statusline = {},
        winbar = {},
        help = {},
      },
    },

    sections = {
      lualine_a = { 'mode' },
      lualine_b = { 'branch' },
      lualine_c = { { 'filename', path = 1 } },
      lualine_x = { 'encoding', 'fileformat', 'filetype' },
      lualine_y = { 'progress' },
      lualine_z = { 'location' },
    },
    inactive_sections = {
      lualine_a = {},
      lualine_b = {},
      lualine_c = { 'filename' },
      lualine_x = { 'location' },
      lualine_y = {},
      lualine_z = {},
    },
  }

  require('lualine').setup(opts)
end

return M
