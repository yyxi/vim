" autocmd FileType mail setl nomodeline tw=72 fo+=aw
autocmd FileType mail setl nomodeline tw=72
au BufNewFile,BufRead *.tf setlocal ai et ts=2 sw=2 sts=2
au BufNewFile,BufRead *.hcl setlocal ai et ts=2 sw=2 sts=2
au BufNewFile,BufRead *.nomad setlocal ft=hcl ai et ts=2 sw=2 sts=2
au BufNewFile,BufRead *.json setlocal et ts=2 sw=2 sts=2
au BufNewFile,BufRead *.js setlocal ft=javascript et ts=2 sw=2 sts=2
au BufNewFile,BufRead *.jsx setlocal ft=javascript.jsx et ts=2 sw=2 sts=2
au BufNewFile,BufRead *.ts setlocal et ts=2 sw=2 sts=2
au BufRead,BufNewFile .{eslintrc,babelrc,prettierrc} setf json
au BufNewFile,BufRead *.scss setlocal et ts=2 sw=2 sts=2
au BufNewFile,BufRead *.vue setlocal ft=vue et ts=2 sw=2 sts=2

if has('nvim')
  luafile ~/.vim/lua/user/filetype.lua
endif
