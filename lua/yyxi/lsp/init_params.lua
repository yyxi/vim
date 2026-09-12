local M = {}

---Return the workspace root represented by LSP initialize parameters.
---Neovim uses `vim.NIL` for protocol null before JSON serialization.
---@param params lsp.InitializeParams
---@return string?
function M.root_path(params)
  local root_uri = params.rootUri
  if root_uri == nil or root_uri == vim.NIL then return nil end

  assert(type(root_uri) == 'string', 'LSP rootUri must be a string or null')
  return vim.uri_to_fname(root_uri)
end

return M
