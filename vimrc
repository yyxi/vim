scripte utf-8
set nocp
filetype off

silent! source $VIMRUNTIME/defaults.vim

filetype plugin indent on
syntax enable

set fenc=utf8 enc=utf8 secure so=5 shm=atI vb t_vb= novb noeb
set dir=~/.vim/tmp/sessions bdir=~/.vim/tmp/backup
set nosol tf nonu noru sc sb spr nofen ve=onemore backup
set gcr=a:blinkon0 ls=2 hi=5000
set hls is nows ic scs so=3 sj=5 siso=7 ss=1 fo-=o sw=4 sts=4 et ai hid
set cpt+=kspell cpt-=t bs=indent,eol,start vi+=! vi='250,<0,r/tmp
set lcs=eol:¬,trail:· shm+=filmnrxoOtT ww=<,>,h,l noswf mat=2 ar
set ruf=%30(%=\:b%n%y%m%r%w\ %l,%c%V\ %P%) wmnu wim=list:longest,full
set wig+=*/.git/*,*/.hg/*,*/.svn/*,*.aux,*.out,*.toc,*.jpg,*.bmp,*.gif
set wig+=*.luac,*.o,*.obj,*.exe,*.dll,*.manifest,*.spl,*.py[co]
set clipboard=unnamedplus go+=a nuw=6
set list listchars=tab:¨¨,trail:·,eol:¬
set noeb vb t_vb= cc=
set bkc=yes nowrap
set ch=2 noshowmode nolist
set signcolumn=no
au GUIEnter * set vb t_vb=
set formatoptions-=t
set nohidden

let loaded_netrwPlugin = 1

if v:version > 703 || v:version == 703 && has('patch541')
  set formatoptions+=j
endif

try
  set udir=~/.vim/tmp/undo undofile
catch /Unknown option/
  " versions of Vim prior to 7.3
endtry

let mapleader="\\"

for fpath in split(globpath('~/.vim/settings', '*.vim'), '\n')
  if fnamemodify(fpath, ':t') =~ '^000'
    exe 'source' fpath
  endif
endfor

if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

if filereadable(expand('~/.vim/vim-bundles'))
  source ~/.vim/vim-bundles
endif

for fpath in split(globpath('~/.vim/settings', '*.vim'), '\n')
  if fnamemodify(fpath, ':t') !~ '^000'
    exe 'source' fpath
  endif
endfor
