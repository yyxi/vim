if has('nvim')
    let g:deoplete#enable_at_startup = 1
    let g:deoplete#max_menu_width = 50
    let g:deoplete#auto_complete_delay = 25
    let g:deoplete#enable_smart_case = 1
    let g:nvim_typescript#type_info_on_hold = 0

    " set completeopt+=menuone
    " set completeopt+=noselect
    " set completeopt+=noinsert
    set shortmess+=c   " Shut off completion messages
    set belloff+=ctrlg " If Vim beeps during completion
    inoremap <silent><expr> <TAB>
                \ pumvisible() ? "\<C-n>" :
                \ <SID>check_back_space() ? "\<TAB>" :
                \ deoplete#mappings#manual_complete()

    function! s:check_back_space() abort "{{{
        let col = col('.') - 1
        return !col || getline('.')[col - 1]  =~ '\s'
    endfunction"}}}

    autocmd CompleteDone * silent! pclose!

    inoremap <expr><C-h> deoplete#smart_close_popup()."\<C-h>"
    inoremap <expr><BS>  deoplete#smart_close_popup()."\<C-h>"

    function g:Multiple_cursors_before()
        let g:deoplete#disable_auto_complete = 1
    endfunction
    function g:Multiple_cursors_after()
        let g:deoplete#disable_auto_complete = 0
    endfunction
else
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
endif
