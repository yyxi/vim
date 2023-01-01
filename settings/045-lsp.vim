if has('nvim')
  luafile ~/.vim/lua/user/lsp.lua

  " if exists(':Format')
  " then
  " endif
  autocmd VimEnter *
    \   delc Format
    \ | delc FormatWrite
    \ | delc FormatWriteLock
endif
