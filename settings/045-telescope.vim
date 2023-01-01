if has('nvim')
  "Mnemonic: [F]iles
  nn <leader>f <cmd>Telescope find_files<cr>

  "Mnemonic: [B]uffer
  nn <leader>b <cmd>Telescope buffers<cr>

  "Mnemonic: [S]ymbols
  nn <leader>s <cmd>Telescope lsp_document_symbols<cr>

  nn <C-Down> <cmd>lua require("trouble").next({ skip_groups = true, jump = true })<cr>
  nn <C-Up> <cmd>lua require("trouble").previous({ skip_groups = true, jump = true })<cr>

  " if global_config.configure_diagnostics then
  "   -- map('n', 'gl', diagnostic('open_float()'))
  "   map('n', '<C-Up>', diagnostic('goto_prev()'))
  "   map('n', '<C-Down>', diagnostic('goto_next()'))
  " end

  luafile ~/.vim/lua/user/telescope.lua
endif
