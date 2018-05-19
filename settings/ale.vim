nmap <silent> <C-p> <Plug>(ale_previous_wrap)
nmap <silent> <C-n> <Plug>(ale_next_wrap)

let g:ale_completion_enabled = 0
let g:ale_set_highlights = 0
let g:ale_set_signs=1

let g:ale_linters = {
    \ 'typescript': ['tslint', 'tsserver', 'typecheck'],
    \ 'vue': []
    \}

let g:ale_fixers = {
    \ 'typescript': ['tslint', 'prettier', 'trim_whitespace'],
    \ 'javascript': ['eslint', 'prettier', 'trim_whitespace'],
    \ 'json': ['prettier'],
    \ 'markdown': ['prettier', 'trim_whitespace'],
    \}

let g:ale_javascript_prettier_options = '--single-quote --no-semi --trailing-comma none'
let g:ale_typescript_prettier_options = '--parser typescript --trailing-comma none --no-semi --single-quote'
let g:ale_markdown_prettier_options = '--parser markdown --print-width 80'
let g:ale_json_prettier_options = '--parser json'
au FileType markdown setlocal tw=80
