nmap <silent> <C-p> <Plug>(ale_previous_wrap)
nmap <silent> <C-n> <Plug>(ale_next_wrap)

let g:ale_set_highlights = 0
let g:ale_set_signs=1

let g:ale_linters = {
    \ 'typescript': ['tslint', 'tsserver', 'typecheck'],
    \ 'vue': []
    \}
" let g:ale_linters = {'vue': []}
" let g:ale_linter_aliases = {'vue': 'html'}

