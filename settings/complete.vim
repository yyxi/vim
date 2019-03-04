" set shortmess+=c   " Shut off completion messages
set belloff+=ctrlg " If Vim beeps during completion

autocmd BufEnter  *  call ncm2#enable_for_buffer()
set completeopt=noinsert,menuone,noselect,preview
" suppress the annoying 'match x of y', 'The only match' and 'Pattern not
" found' messages
set shortmess+=c

" CTRL-C doesn't trigger the InsertLeave autocmd . map to <ESC> instead.
inoremap <c-c> <ESC>

" When the <Enter> key is pressed while the popup menu is visible, it only
" hides the menu. Use this mapping to close the menu and also start a new
" line.
inoremap <expr> <CR> (pumvisible() ? "\<c-y>\<cr>" : "\<CR>")

" Use <TAB> to select the popup menu:
inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"

" Required for operations modifying multiple buffers like rename.
set hidden

nnoremap <F5> :call LanguageClient_contextMenu()<CR>

let g:LanguageClient_serverCommands = {
    \ 'rust': ['~/.cargo/bin/rustup', 'run', 'stable', 'rls'],
    \ 'javascript': ['javascript-typescript-stdio'],
    \ 'typescript': ['javascript-typescript-stdio'],
    \ 'javascript.jsx': ['javascript-typescript-stdio'],
    \ 'python': ['/usr/local/bin/pyls'],
    \ }

let g:LanguageClient_windowLogMessageLevel="Error"
let g:LanguageClient_loggingLevel="Error"

nnoremap <buffer>
  \ <leader>s :call LanguageClient_textDocument_documentSymbol()<cr>

function LC_maps()
    if has_key(g:LanguageClient_serverCommands, &filetype)
        nnoremap <buffer> <silent> K :call LanguageClient#textDocument_hover()<cr>
        nnoremap <buffer> <silent> gd :call LanguageClient#textDocument_definition()<CR>
        nnoremap <buffer> <silent> <F2> :call LanguageClient#textDocument_rename()<CR>
    endif
endfunction

autocmd FileType * call LC_maps()

let g:LanguageClient_diagnosticsEnable=0
