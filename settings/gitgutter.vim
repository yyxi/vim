if exists('&signcolumn')  " Vim 7.4.2201
  set signcolumn=yes
else
  let g:gitgutter_sign_column_always = 1
endif

let g:gitgutter_map_keys = 0
let g:gitgutter_override_sign_column_highlight = 0
