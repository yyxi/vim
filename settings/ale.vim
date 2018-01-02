nmap <silent> <C-p> <Plug>(ale_previous_wrap)
nmap <silent> <C-n> <Plug>(ale_next_wrap)

let g:ale_set_highlights = 0
let g:ale_set_signs=1

let g:ale_linters = {
    \ 'typescript': ['tslint', 'tsserver', 'typecheck'],
    \ 'vue': []
    \}

let g:ale_fixers = {
    \ 'typescript': ['tslint', 'prettier', 'trim_whitespace'],
    \ 'javascript': ['eslint', 'prettier', 'trim_whitespace'],
    \}

let g:ale_javascript_prettier_options = '--single-quote --no-semi --trailing-comma none'
let g:ale_typescript_prettier_options = '--parser typescript --trailing-comma none --no-semi --single-quote'
" let g:ale_scss_prettier_options = '--parser scss --trailing-comma none --no-semi --single-quote --tab-width 1'
