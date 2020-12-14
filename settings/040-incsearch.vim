map /  <Plug>(incsearch-forward)
map ?  <Plug>(incsearch-backward)
map g/ <Plug>(incsearch-stay)

augroup incsearch-keymap
    autocmd!
    autocmd VimEnter * call s:incsearch_keymap()
augroup END

function! s:incsearch_keymap()
    IncSearchNoreMap <Up> <Over>(incsearch-prev)
    IncSearchNoreMap <Down> <Over>(incsearch-next)
endfunction

