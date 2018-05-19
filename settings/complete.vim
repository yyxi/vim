if has('nvim')
    " TODO: https://github.com/mhartington/nvim-typescript/issues/115
    " let deoplete#num_processes = 1
    let g:deoplete#enable_at_startup = 1
    let g:deoplete#max_menu_width = 50
    let g:deoplete#auto_complete_delay = 25
    let g:deoplete#enable_smart_case = 1
    let g:nvim_typescript#type_info_on_hold = 0

    inoremap <silent><expr> <TAB>
                \ pumvisible() ? "\<C-n>" :
                \ <SID>check_back_space() ? "\<TAB>" :
                \ deoplete#mappings#manual_complete()
    function! s:check_back_space() abort "{{{
        let col = col('.') - 1
        return !col || getline('.')[col - 1]  =~ '\s'
    endfunction"}}}

    set completeopt+=menuone
    set completeopt+=noselect
    set completeopt+=noinsert
    set shortmess+=c   " Shut off completion messages
    set belloff+=ctrlg " If Vim beeps during completion
else
    " set completeopt=menu,menuone,preview,noinsert
    set completeopt-=preview
    set completeopt+=longest,menuone,noselect
    set completeopt+=noinsert
    set shortmess+=c   " Shut off completion messages
    set belloff+=ctrlg " If Vim beeps during completion
    let g:mucomplete#enable_auto_at_startup = 1
    let g:tsuquyomi_completion_detail = 1
    let g:tsuquyomi_disable_quickfix = 0
    let g:tsuquyomi_single_quote_import = 1

    imap <unique> <tab> <plug>(MUcompleteFwd)
    imap <unique> <s-tab> <plug>(MUcompleteBwd)
    let g:mucomplete#no_mappings = 1
    let g:mucomplete#no_popup_mappings = 1
    let g:tsuquyomi_disable_quickfix = 1

    let g:mucomplete#can_complete = {}
    let g:mucomplete#chains = {}
    let g:mucomplete#chains.typescript = ['path', 'omni']

    let g:mucomplete#can_complete.typescript = {
        \    'omni': { t -> strlen(&l:omnifunc) > 0 && t =~# '\%(\k\k\|\.\)$' }
        \  }
endif
