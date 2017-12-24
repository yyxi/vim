au BufNewFile,BufRead *.scss setlocal et ts=2 sw=2 sts=2

" let g:neoformat_verbose = 1
let g:neoformat_scss_stylelint = {
    \ 'exe': 'bash',
    \ 'args': ['-c', "stylelint -q --fix || true"],
    \ 'stdin': 1
    \ }

let g:neoformat_enabled_scss = ['stylelint']
