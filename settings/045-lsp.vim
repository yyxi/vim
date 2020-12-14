if has('nvim')
  nnoremap <silent> K     <cmd>lua vim.lsp.buf.hover()<CR>
  nnoremap <silent> <c-k> <cmd>lua vim.lsp.buf.signature_help()<CR>

  nn <silent><leader>s :DocumentSymbols<CR>
  nn <silent><leader>S :WorkspaceSymbols<CR>
  nn <silent><leader>a :CodeActions<CR>
  vn <silent><leader>a :RangeCodeActions<CR> 

  nn <silent> xr <cmd>lua vim.lsp.buf.rename()<CR>
  nn <silent> xR :References<CR>
  nn <silent> xd :Definitions<CR>
  nn <silent> xD :Declarations<CR>
  nn <silent> xt :TypeDefinitions<CR>
  nn <silent> xi :Implementations<CR>
  nmap <silent> <C-Up> <cmd>lua vim.lsp.diagnostic.goto_prev()<CR>
  nmap <silent> <C-Down> <cmd>lua vim.lsp.diagnostic.goto_next()<CR>

  luafile ~/.vim/lua/user/lsp.lua
endif
