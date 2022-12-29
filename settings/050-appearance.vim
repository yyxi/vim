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
let g:airline#extensions#searchcount#enabled = 0
let g:airline_theme                          = "minimalist"
let g:gruvbox_contrast_dark                  = "hard"
let g:gruvbox_sign_column                    = "dark0_hard"
let g:gruvbox_invert_selection               = 0

if has('nvim')
  let g:indent_blankline_char_list = ['|', '¦', '┆', '┊']
  let g:indent_blankline_use_treesitter = v:true
  let g:indent_blankline_show_first_indent_level = v:false
  let g:indent_blankline_filetype_exclude = ['help']
  highlight IndentBlanklineChar cterm=nocombine gui=nocombine ctermfg=8 guifg=#332E33
endif

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
au FileType * if &buftype == 'nofile' | setlocal syntax=off | endif

" autocmd FileType * unlet! g:airline#extensions#whitespace#checks
" autocmd FileType taskedit let g:airline#extensions#whitespace#checks = [ 'indent' ]
" autocmd FileType mail let g:airline#extensions#whitespace#checks = [ 'indent' ]

if $TERM=~'linux'
    set bg=dark
    colo default
    syntax on
else
    set mouse=nv
    set bg=dark
    set termguicolors

    if has('nvim')
      luafile ~/.vim/lua/user/base16.lua

    else
      colo base16-gruvbox-dark-hard
    endif

    highlight clear SignColumn
    highlight link mkdLineBreak NONE
    highlight Normal ctermfg=7 ctermbg=NONE guifg=#d5c4a1 guibg=NONE
    hi! link CocMenuSel PmenuSel
endif

augroup quickfix
    autocmd!
    autocmd FileType qf setlocal wrap
augroup END
