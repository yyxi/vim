local M = {}

function M.mini_hipatterns()
  local hipatterns = require('mini.hipatterns')

  hipatterns.setup({
    highlighters = {
      -- Highlight standalone 'FIXME', 'HACK', 'TODO', 'NOTE'
      fixme = {
        pattern = '%f[%w]()FIXME()%f[%W]',
        group = 'MiniHipatternsFixme',
      },
      hack = {
        pattern = '%f[%w]()HACK()%f[%W]',
        group = 'MiniHipatternsHack',
      },
      todo = {
        pattern = '%f[%w]()TODO()%f[%W]',
        group = 'MiniHipatternsTodo',
      },
      note = {
        pattern = '%f[%w]()NOTE()%f[%W]',
        group = 'MiniHipatternsNote',
      },

      -- Highlight hex color strings (`#rrggbb`) using that color
      hex_color = hipatterns.gen_highlighter.hex_color(),
    },
  })
end

function M.treesitter()
  vim.env.EXTENSION_WIKI_LINK = 1

  require('yyxi.utilities.treesitter').setup()
end

function M.ts_autotag()
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
