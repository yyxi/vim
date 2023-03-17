if has('nvim')
lua << EOF
  require("better_escape").setup {
    mapping = {"jj"},
    clear_empty_lines = false,
    keys = "<Esc>"
  }
EOF
endif
