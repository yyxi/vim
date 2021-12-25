if has('nvim')
  "Mnemonic: [F]iles
  nn <leader>f <cmd>Telescope find_files<cr>

  "Mnemonic: [B]uffer
  nn <leader>b <cmd>Telescope buffers<cr>

  luafile ~/.vim/lua/user/telescope.lua
endif
