au BufNewFile,BufRead *.json setlocal et ts=2 sw=2 sts=2
au BufNewFile,BufRead *.js setlocal ft=javascript et ts=2 sw=2 sts=2
au BufNewFile,BufRead *.jsx setlocal ft=javascript.jsx et ts=2 sw=2 sts=2
au BufNewFile,BufRead *.ts setlocal et ts=2 sw=2 sts=2
au BufRead,BufNewFile .{eslintrc,babelrc,prettierrc} setf json
