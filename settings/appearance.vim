let g:airline#extensions#coc#enabled         = 0
let g:airline#extensions#hunks#enabled       = 0
let g:airline#extensions#hunks#non_zero_only = 1
let g:airline#extensions#syntastic#enabled   = 0
let g:airline_exclude_preview                = 1
let g:airline_powerline_fonts                = 0
let g:airline_right_alt_sep                  = ""
let g:airline_section_error                  = ""
let g:airline_skip_empty_sections            = 1
let g:airline_skip_empty_sections            = 1
let g:airline_theme                          = "monocolor_white"

if !exists('g:airline_symbols')
  let g:airline_symbols = {}
endif

let g:airline_symbols.space     = "\ua0"
let g:airline_symbols.linenr    = ''
let g:airline_symbols.linenr    = ''
let g:airline_symbols.notexists = "?"
let g:airline_symbols.maxlinenr = ''

au FileType help,qf setl nowrap nofen nospell nocul nolist
au FileType help,qf setl stl=\ %n\ \ %f%=%L\ lines
highlight clear SignColumn

" autocmd FileType * unlet! g:airline#extensions#whitespace#checks
" autocmd FileType taskedit let g:airline#extensions#whitespace#checks = [ 'indent' ]
" autocmd FileType mail let g:airline#extensions#whitespace#checks = [ 'indent' ]

if $TERM=~'linux'
    " set bg=dark " term=linux
    colo default
    syntax on
else
    set mouse=nv
    set termguicolors
    colo monocolor_white
endif

augroup quickfix
    autocmd!
    autocmd FileType qf setlocal wrap
augroup END
