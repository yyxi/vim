let g:airline#extensions#syntastic#enabled = 0
let g:airline#extensions#hunks#enabled = 0
let g:airline#extensions#hunks#non_zero_only = 1
let g:airline_powerline_fonts=0
let g:airline_theme="gruvbox"
let g:bufferline_echo=0
let g:bufferline_show_bufnr = 0
let g:airline_skip_empty_sections = 1
let g:airline_exclude_preview = 1
let g:gitgutter_override_sign_column_highlight = 1
let g:gruvbox_sign_column = "dark0"
let g:gruvbox_contrast_dark = "hard"
" let g:gruvbox_invert_signs = 0
let g:airline_skip_empty_sections = 1
let g:gruvbox_bold = 1
let g:gruvbox_undercurl = 1

if !exists('g:airline_symbols')
  let g:airline_symbols = {}
endif
let g:airline_symbols.space = "\ua0"
let g:airline_section_error = ""
let g:airline_right_alt_sep = ""
let g:airline_symbols.linenr = '☰'
let g:airline_symbols.notexists = "?"

" let g:airline_section_z = '%3pp% %l:%c'
call airline#parts#define_raw('linenr', '%l')
call airline#parts#define_accent('linenr', 'bold')
let g:airline_section_z = airline#section#create(['%3p%%  ',
            \ g:airline_symbols.linenr .' ', 'linenr', ':%c '])

au FileType help,qf setl nowrap nofen nospell nocul nolist
au FileType help,qf setl stl=\ %n\ \ %f%=%L\ lines
highlight clear SignColumn

autocmd FileType * unlet! g:airline#extensions#whitespace#checks
autocmd FileType taskedit let g:airline#extensions#whitespace#checks = [ 'indent' ]
autocmd FileType mail let g:airline#extensions#whitespace#checks = [ 'indent' ]

function CheckConsole()
    let l:isconsole = 0

    if exists('$SSH_CLIENT')
        let l:isconsole = 0
    elseif exists('$SSH_TTY')
        let l:isconsole = 0
    endif

    if !empty(glob("/.dockerinit"))
        let l:isconsole = 0
    endif

    return l:isconsole
endfunction

if CheckConsole() == 1
    set bg=dark " term=linux
    colo slate
    syntax on
else
    set mouse=nv
    colo gruvbox
    set bg=dark
    set noshowmode
    hi NonText ctermfg=magenta
    hi SpecialKey ctermfg=magenta
    let g:airline_theme='minimalist'
    highlight Normal ctermbg=NONE
    au VimEnter * RainbowParenthesesToggle
    au Syntax * RainbowParenthesesLoadRound
    au Syntax * RainbowParenthesesLoadSquare
    au Syntax * RainbowParenthesesLoadBraces
endif

augroup quickfix
    autocmd!
    autocmd FileType qf setlocal wrap
augroup END
