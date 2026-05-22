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

  local configs = require('nvim-treesitter.parsers').get_parser_configs()
  configs.markdown.install_info.requires_generate_from_grammar = true
  configs.markdown_inline.install_info.requires_generate_from_grammar = true

  ---@diagnostic disable-next-line: missing-fields
  require('nvim-treesitter.configs').setup({
    highlight = {
      enable = true,
      additional_vim_regex_highlighting = false,
    },
    indent = {
      enable = true,
    },
    playground = {
      enable = true,
    },
    -- matchup = {
    --   enable = true,
    --   disable_virtual_text = true,
    -- },
    incremental_selection = {
      enable = false,
      keymaps = {
        init_selection = 'vv',
        node_incremental = '<Right>',
        scope_incremental = '<Up>',
        node_decremental = '<Left>',
      },
    },
    ensure_installed = {
      'bash',
      'bibtex',
      'cmake',
      'comment',
      'css',
      'dockerfile',
      'dot',
      'eex',
      'elixir',
      'erlang',
      'fish',
      'git_config',
      'git_rebase',
      'gitattributes',
      'gitcommit',
      'gitignore',
      'glsl',
      'go',
      'graphql',
      'hcl',
      'heex',
      'html',
      'http',
      'jq',
      'javascript',
      'jsdoc',
      'sql',
      'json',
      'json5',
      'jsonc',
      'latex',
      'lua',
      'make',
      'markdown',
      'markdown_inline',
      'mermaid',
      'perl',
      'prisma',
      'proto',
      'python',
      'r',
      'rust',
      'terraform',
      'toml',
      'tsx',
      'typescript',
      'vim',
      'vimdoc',
      'vue',
      'wgsl',
      'yaml',
    },
  })
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
