if has('nvim')
    " use <tab> and <s-tab> to navigate through popup menu
    inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
    inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"

    " set completeopt to have a better completion experience
    set completeopt=menuone,noinsert,noselect

    set updatetime=300
    " avoid showing message extra message when using completion
    set shortmess+=c

    let g:completion_enable_auto_hover      = 0
    let g:completion_enable_auto_signature  = 0
    let g:completion_sorting                = "none"
    let g:completion_matching_smart_case    = 1
    let g:completion_trigger_keyword_length = 2
    " let g:completion_matching_ignore_case = 1

    " auto close popup menu when finish completion
    augroup completionstuff
      autocmd! CompleteDone * if pumvisible() == 0 | pclose | endif
    augroup END

    let g:completion_chain_complete_list = {
        \ 'vim': [
        \    {'mode': '<c-p>'},
        \    {'mode': '<c-n>'}
        \ ],
        \ 'typescript': [
        \    {'complete_items': ['lsp', 'path']},
        \    {'mode': '<c-p>'},
        \    {'mode': '<c-n>'}
        \ ],
        \ 'default': [
        \    {'complete_items': ['lsp', 'ts', 'path']},
        \    {'mode': '<c-p>'},
        \    {'mode': '<c-n>'}
        \ ]
    \}

    let g:completion_auto_change_source = 1

    autocmd BufEnter * lua require'completion'.on_attach()
endif

" let g:completion_chain_complete_list = {
" 			\'default' : {
" 			\	'default' : [
" 			\		{'complete_items' : ['lsp', 'snippet', 'buffer']},
" 			\		{'mode' : 'file'}
" 			\	],
" 			\	},
" 			\'c' : [
" 			\	{'complete_items': ['ts', 'lsp', 'snippet']}
" 			\	],
" 			\'python' : [
" 			\	{'complete_items': ['ts', 'lsp', 'snippet']}
" 			\	],
" 			\'lua' : [
" 			\	{'complete_items': ['ts', 'lsp', 'snippet']}
" 			\	],
" 			\}
