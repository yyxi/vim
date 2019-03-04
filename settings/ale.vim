nmap <silent> <C-p> <Plug>(ale_previous_wrap)
nmap <silent> <C-n> <Plug>(ale_next_wrap)

let g:ale_completion_enabled = 0
let g:ale_set_highlights = 0
let g:ale_set_signs=1

let g:ale_linters = {
    \ 'typescript': ['tslint', 'tsserver', 'typecheck'],
    \}

let g:ale_fixers = {
    \ 'typescript': ['tslint', 'prettier', 'trim_whitespace'],
    \ 'javascript': ['eslint', 'prettier', 'trim_whitespace'],
    \ 'json': ['prettier'],
    \ 'markdown': ['prettier', 'trim_whitespace'],
    \}

au FileType markdown setlocal tw=80
