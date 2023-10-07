require('telescope').setup({
  pickers = {
    find_files = {
      find_command = {
        'rg',
        '-L',
        '--files',
        '--color',
        'never',
        '--hidden',
        '--glob',
        '!.git',
      },
    },
  },
  -- file_ignore_patterns = { '.git' },
  extensions = {
    fzf = {
      fuzzy = true, -- false will only do exact matching
      override_generic_sorter = true, -- override the generic sorter
      override_file_sorter = true, -- override the file sorter
      case_mode = 'smart_case', -- or "ignore_case" or "respect_case"
    },
  },
})

require('telescope').load_extension('fzf')
