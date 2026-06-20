-- Overlay that registers every TOML-suffixed schema from the offline catalog
-- with the Tombi LSP via `tombi/associateSchema`. Replaces the older
-- `vendor/schemas/tombi.toml` static config: the same `vendor/schemas/catalog.lua`
-- already used by jsonls/yamlls is now the single source of truth for tombi too.
--
-- Why no embedded-name skip list: Tombi's schema store resolves the first
-- matching entry per file (`crates/tombi-schema-store/src/store.rs:822-840`).
-- Once the in-process catalog has finished loading, Tombi's embedded
-- `tombi://` schemas for Cargo/PyProject/Tombi sit ahead of any
-- `force = false` association we push, so the embedded copies win for those
-- three files. For everything else our association is the only match.
--
-- A note on cost: Tombi clears workspace diagnostics and republishes after
-- *every* notification (`crates/tombi-lsp/src/handler/associate_schema.rs:67-82`).
-- A coalesced multi-association request would be welcome upstream; until then
-- a one-time storm at attach is acceptable for the offline benefit.

local M = {}

local offline_schemas = require('yyxi.utilities.offline_schemas')

local TOML_SUFFIX = '.toml'

-- Track which clients we've already overlaid so :LspRestart and the implicit
-- restarts vim.lsp does on root change don't make Tombi's schema list grow
-- linearly. `tombi/associateSchema` appends without deduping
-- (store.rs:1059-1066), so the cost of not gating this would compound per
-- restart.
local attached_client_ids = {}

---@param pattern any
---@return boolean
local function is_toml_pattern(pattern)
  if type(pattern) ~= 'string' then return false end
  return pattern:sub(-#TOML_SUFFIX):lower() == TOML_SUFFIX
end

---@param file_match string|string[]|nil
---@return string[]|nil
local function toml_subset(file_match)
  if file_match == nil then return nil end
  if type(file_match) == 'string' then
    return is_toml_pattern(file_match) and { file_match } or nil
  end
  if type(file_match) ~= 'table' then return nil end
  local out = {}
  for _, pattern in ipairs(file_match) do
    if is_toml_pattern(pattern) then table.insert(out, pattern) end
  end
  return #out > 0 and out or nil
end

---Send one `tombi/associateSchema` notification per catalog entry whose
---`fileMatch` contains at least one TOML-suffixed pattern. Patterns that
---are not TOML-suffixed are filtered out before sending. The notification
---uses the default `force = false`, so Tombi's embedded catalog still
---wins for any schema it covers.
---@param client vim.lsp.Client
---@return integer count Notifications sent on this call (0 on a repeat attach).
function M.attach(client)
  if attached_client_ids[client.id] then return 0 end
  attached_client_ids[client.id] = true

  local catalog = offline_schemas.json.load()
  local count = 0
  for _, entry in ipairs(catalog.schemas) do
    local include = toml_subset(entry.fileMatch)
    if include ~= nil and type(entry.url) == 'string' then
      -- `tombi/associateSchema` is a Tombi-specific notification; lua-ls's LSP
      -- stubs only know standard methods, so we have to cross the type boundary
      -- explicitly here.
      ---@diagnostic disable-next-line: param-type-mismatch
      client:notify('tombi/associateSchema', {
        uri = entry.url,
        fileMatch = include,
      })
      count = count + 1
    end
  end
  return count
end

-- Internal: expose helpers for the spec. Production callers should use
-- `M.attach(client)` only.
M._is_toml_pattern = is_toml_pattern
M._toml_subset = toml_subset
M._reset_for_tests = function() attached_client_ids = {} end

return M
