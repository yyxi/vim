" let g:asyncomplete_remove_duplicates = 1
" inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
" inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
" inoremap <expr> <cr> pumvisible() ? "\<C-y>\<cr>" : "\<cr>"
" set completeopt+=preview
" set completeopt+=menuone
" set completeopt+=noselect
" set completeopt+=noinsert
" set shortmess+=c   " Shut off completion messages
" set belloff+=ctrlg " If Vim beeps during completion
" autocmd! CompleteDone * if pumvisible() == 0 | pclose | endif

" let g:asyncomplete_auto_popup = 1

" function! s:check_back_space() abort
"     let col = col('.') - 1
"     return !col || getline('.')[col - 1]  =~ '\s'
" endfunction

" inoremap <silent><expr> <TAB>
"   \ pumvisible() ? "\<C-n>" :
"   \ <SID>check_back_space() ? "\<TAB>" :
"   \ asyncomplete#force_refresh()
" inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"
"
" if executable('typescript-language-server')
"     au User lsp_setup call lsp#register_server({
"                 \ 'name': 'typescript-language-server',
"                 \ 'cmd': {server_info->[&shell, &shellcmdflag, 'typescript-language-server --stdio']},
"                 \ 'root_uri':{server_info->lsp#utils#path_to_uri(lsp#utils#find_nearest_parent_file_directory(lsp#utils#get_buffer_path(), 'tsconfig.json'))},
"                 \ 'whitelist': ['typescript'],
"                 \ })
" endif

"  mucomplete

set completeopt+=menuone
inoremap <expr> <c-e> mucomplete#popup_exit("\<c-e>")
inoremap <expr> <c-y> mucomplete#popup_exit("\<c-y>")
inoremap <expr>  <cr> mucomplete#popup_exit("\<cr>")
set completeopt+=noselect
set completeopt+=noinsert
set shortmess+=c   " Shut off completion messages
set belloff+=ctrlg " If Vim beeps during completion
let g:mucomplete#enable_auto_at_startup = 1

let g:tsuquyomi_completion_detail = 1
let g:tsuquyomi_disable_quickfix = 0
let g:tsuquyomi_single_quote_import = 1

