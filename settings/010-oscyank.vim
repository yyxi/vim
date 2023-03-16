let g:oscyank_silent = v:true
let g:oscyank_term = 'default'
autocmd TextYankPost * if v:event.operator is 'y' && v:event.regname is '' | execute 'OSCYankRegister "' | endif

" autocmd TextYankPost *
"     \ if v:event.operator is 'y' && v:event.regname is '+' |
"     \ execute 'OSCYankRegister +' |
"     \ endif
