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

if has('nvim')
  set laststatus=3

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
" au FileType help setl stl=
" au FileType * if &buftype == 'nofile' | setlocal syntax=off | endif

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

    hi! link NormalFloat Normal
    hi! link FloatBorder Normal
    hi! link DiagnosticFloatingError Normal
    hi! link DiagnosticFloatingHint Normal
    hi! link DiagnosticFloatingInfo Normal
    hi! link DiagnosticFloatingWarn Normal
    hi! link WinSeparator Normal
    hi! link TroubleCount Normal
    hi! link TroubleIndent Normal
    hi! link TroubleFoldIcon Comment
    hi! link TroubleSignError Comment
    hi! link TroubleSignWarning Comment
    hi! link TroubleSignInformation Comment
    hi! link TroubleSignHint Comment
    hi! link TroubleSignOther Comment
    hi! link TroubleLocation Comment
endif
