let g:go_fmt_autosave = 0
let g:go_play_open_browser = 0
let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
let g:go_highlight_structs = 1
let g:go_highlight_operators = 1
let g:go_highlight_build_constraints = 1
let g:go_highlight_trailing_whitespace_error = 0
let g:go_highlight_space_tab_error = 0
let g:go_highlight_chan_whitespace_error = 0
let g:go_highlight_array_whitespace_error = 0
let g:go_fmt_fail_silently = 1
let g:go_def_mapping_enabled = 0

au FileType go nmap <leader>gr <Plug>(go-run)
au FileType go nmap <leader>gb <Plug>(go-build)
au FileType go nmap <leader>gt <Plug>(go-test)
au FileType go nmap <leader>gc <Plug>(go-coverage)

au FileType go nmap <Leader>gd <Plug>(go-doc)
au FileType go nmap <Leader>gv <Plug>(go-doc-vertical)
au FileType go nmap <Leader>gi <Plug>(go-implements)

au BufNewFile,BufRead *.go setlocal noet ts=4 sw=4 sts=4
