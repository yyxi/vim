local M = {}

function M.setup()
  local telescope = require('telescope')

  telescope.setup({
    defaults = {
      results_title = '',
      prompt_title = '',
      dynamic_preview_title = false,
      layout_strategy = 'flex',
      mappings = {},
      winblend = 10,
      prompt_prefix = ' ',
      selection_caret = '  ',
      entry_prefix = '  ',
      initial_mode = 'insert',
      -- path_display = { 'truncate' },
      path_display = {
        'filename_first',
      },
      set_env = { ['COLORTERM'] = 'truecolor' },
      vimgrep_arguments = {
        'rg',
        '--color=never',
        '--no-heading',
        '--with-filename',
        '--line-number',
        '--column',
        '--smart-case',
        '--hidden',
        '--trim',
        '--glob',
        '!.git',
      },
      preview = {
        filesize_limit = 1, -- MB
      },
    },
    pickers = {
      find_files = {
        find_command = {
          'rg',
          '--color=never',
          '--no-heading',
          '-L',
          '--files',
          '--hidden',
          '--glob',
          '!.git',
        },
      },
      buffers = {
        select_current = true,
        sort_mru = true,
      },
    },
    extensions = {
      ['ui-select'] = {
        layout_strategy = 'flex',
      },
      fzf = {
        fuzzy = true, -- false will only do exact matching
        override_generic_sorter = true, -- override the generic sorter
        override_file_sorter = true, -- override the file sorter
        case_mode = 'smart_case', -- or "ignore_case" or "respect_case"
      },
    },
  })

  telescope.load_extension('fzf')
  telescope.load_extension('yank_history')
  telescope.load_extension('ui-select')
end

return M
