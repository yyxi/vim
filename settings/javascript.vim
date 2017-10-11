au BufNewFile,BufRead *.json setlocal et ts=2 sw=2 sts=2
au BufNewFile,BufRead *.js setlocal ft=javascript et ts=2 sw=2 sts=2
au BufNewFile,BufRead *.jsx setlocal ft=javascript.jsx et ts=2 sw=2 sts=2
au BufNewFile,BufRead *.ts setlocal et ts=2 sw=2 sts=2
au BufRead,BufNewFile .{eslintrc,babelrc} setf json

let g:neoformat_enabled_typescript = ['prettier']
let g:neoformat_typescript_prettier = {
    \ 'exe': 'prettier',
    \ 'args': ['--parser', 'typescript', '--no-semi', '--single-quote', '--stdin'],
    \ 'stdin': 1,
    \ }

let g:neoformat_enabled_javascript = ['prettier']
let g:neoformat_javascript_prettier = {
    \ 'exe': 'prettier',
    \ 'args': ['--no-semi', '--single-quote', '--stdin'],
    \ 'stdin': 1,
    \ }
