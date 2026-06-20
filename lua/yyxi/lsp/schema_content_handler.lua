-- LSP request handler for `vscode/content`, the schema-fetch protocol used by
-- vscode-json-language-server and yaml-language-server. The servers issue this
-- request whenever a document declares an http(s) `$schema` URL (or one of our
-- entries did, before we rewrote them to file://). Routing it through nvim
-- keeps the editor fully offline: schemastore-hosted URLs are served from the
-- vendored tree; anything else gets an empty schema body so the LSP treats it
-- as a no-op rather than logging a network failure.

local M = {}

local offline_schemas = require('yyxi.utilities.offline_schemas')

-- An empty JSON schema is a valid no-op: it neither validates nor completes,
-- so the LSP silently moves on instead of surfacing a load error.
local EMPTY_SCHEMA = '{}'

---@param params any The raw request payload sent by the LSP.
---@return string|nil  The URI as a string, or nil if it couldn't be extracted.
local function extract_uri(params)
  if type(params) == 'string' then return params end
  if type(params) == 'table' then
    local candidate = params.uri or params[1]
    if type(candidate) == 'string' then return candidate end
  end
  return nil
end

---@param path string
---@return string|nil
local function read_file(path)
  local fd = vim.uv.fs_open(path, 'r', 420) -- 0644
  if fd == nil then return nil end
  local stat = vim.uv.fs_fstat(fd)
  if stat == nil then
    vim.uv.fs_close(fd)
    return nil
  end
  local data = vim.uv.fs_read(fd, stat.size, 0)
  vim.uv.fs_close(fd)
  return data
end

---LSP request handler for `vscode/content`.
---@param _ any LSP error (always nil for server-originated requests we accept).
---@param params any The URI to fetch, or a table containing it.
---@return string body Schema body to return to the LSP.
function M.handler(_, params, _, _)
  local uri = extract_uri(params)
  if uri == nil then return EMPTY_SCHEMA end
  local path = offline_schemas.resolve_local_schema_path(uri)
  if path == nil then return EMPTY_SCHEMA end
  return read_file(path) or EMPTY_SCHEMA
end

return M
