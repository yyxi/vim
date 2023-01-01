if has('nvim')
  luafile ~/.vim/lua/user/treesitter.lua

  set foldmethod=expr
  set foldexpr=nvim_treesitter#foldexpr()
  set nofoldenable
endif
