local M = { json = {}, yaml = {} }

local environment = require('yyxi.utilities.environment')

local CATALOG_RELATIVE_PATH = { 'vendor', 'schemas', 'catalog.lua' }
local VENDORED_SCHEMAS_PATH =
  { 'vendor', 'git', 'worktrees', 'schemastore', 'src', 'schemas', 'json' }
-- Same shape as manage's SCHEMASTORE_URL_PATTERN; keep them in lock-step.
local SCHEMASTORE_URL_PATTERN = '^https?://[^/]*schemastore%.org/(.+)$'

local cached_catalog = nil

---@class OfflineSchemaEntry
---@field name string
---@field description? string
---@field fileMatch string | string[]
---@field url string
---@field versions? table<string, string>

---@class OfflineSchemaCatalog
---@field schemas OfflineSchemaEntry[]
---@field index table<string, integer>

---@param entries table[]
---@param root string
---@return OfflineSchemaCatalog
local function build_catalog(entries, root)
  -- Refuse to silently emit broken URLs when repository_root() returned a
  -- relative path. Without this guard, jsonls/yamlls would 404 in silence.
  assert(root:sub(1, 1) == '/', 'offline_schemas: repository root must be absolute, got: ' .. root)
  local prefix = 'file://' .. root .. '/'
  local schemas = {}
  local index = {}
  for _, raw in ipairs(entries) do
    if type(raw) == 'table' and type(raw.path) == 'string' and type(raw.name) == 'string' then
      local entry = {
        name = raw.name,
        description = raw.description,
        fileMatch = raw.fileMatch,
        url = prefix .. raw.path,
      }
      if type(raw.versions) == 'table' then
        local versions = {}
        for key, version_path in pairs(raw.versions) do
          if type(key) == 'string' and type(version_path) == 'string' then
            versions[key] = prefix .. version_path
          end
        end
        if next(versions) ~= nil then entry.versions = versions end
      end
      table.insert(schemas, entry)
      index[entry.name] = #schemas
    end
  end
  return { schemas = schemas, index = index }
end

---@return OfflineSchemaCatalog
local function load_catalog()
  if cached_catalog ~= nil then return cached_catalog end

  local path = environment.repository_path(CATALOG_RELATIVE_PATH)
  if not environment.exists(path) then
    -- Silent fail-open: the LSPs simply get no offline schemas. `./manage
    -- install` is the recovery step; surface that via `:checkhealth` rather
    -- than by interrupting the editor session.
    cached_catalog = { schemas = {}, index = {} }
    return cached_catalog
  end

  local chunk, load_err = loadfile(path)
  if chunk == nil then
    vim.notify(
      'offline_schemas: failed to load ' .. path .. ': ' .. tostring(load_err),
      vim.log.levels.ERROR
    )
    cached_catalog = { schemas = {}, index = {} }
    return cached_catalog
  end

  local ok, value = pcall(chunk)
  if not ok or type(value) ~= 'table' or type(value.entries) ~= 'table' then
    vim.notify('offline_schemas: ' .. path .. ' produced unexpected data', vim.log.levels.ERROR)
    cached_catalog = { schemas = {}, index = {} }
    return cached_catalog
  end

  cached_catalog = build_catalog(value.entries, environment.repository_root())
  return cached_catalog
end

---@param schemas OfflineSchemaEntry[]
---@param index table<string, integer>
---@param name string
---@return OfflineSchemaEntry|nil, integer|nil
local function find_in(schemas, index, name)
  local i = index[name]
  if i == nil then return nil, nil end
  return schemas[i], i
end

---@return OfflineSchemaCatalog
function M.load() return load_catalog() end

---@return OfflineSchemaCatalog
function M.json.load() return load_catalog() end

---@param name string
---@return OfflineSchemaEntry|nil, integer|nil
function M.json.get(name)
  local catalog = load_catalog()
  return find_in(catalog.schemas, catalog.index, name)
end

-- Resolve a remote schemastore URL (as it may appear in a document's `$schema`
-- field) to the absolute filesystem path of the vendored schema. Returns nil
-- when the URL does not match the schemastore pattern or the corresponding
-- file has not been vendored locally. The classification rule mirrors
-- `classify_schemastore_url` in `manage`.
---@param url string
---@return string|nil
function M.resolve_local_schema_path(url)
  if type(url) ~= 'string' then return nil end
  local tail = url:match(SCHEMASTORE_URL_PATTERN)
  if tail == nil then return nil end
  if tail:sub(-5) ~= '.json' then tail = tail .. '.json' end
  -- Reject any tail that could escape the vendored tree. Schemastore stores
  -- every schema flat under src/schemas/json/, so a legitimate tail is one
  -- filename — no slashes, no `..`.
  if tail:find('/', 1, true) or tail:find('..', 1, true) then return nil end
  local parts = vim.list_extend({}, VENDORED_SCHEMAS_PATH)
  table.insert(parts, tail)
  local path = environment.repository_path(parts)
  if environment.exists(path) then return path end
  return nil
end

-- Test seam: install a precomputed catalog and discard cached state. Intended
-- only for the plenary spec; production code uses `load_catalog` exclusively.
---@param entries OfflineSchemaEntry[]|nil
---@param root string|nil
function M._set_catalog_for_tests(entries, root)
  if entries == nil then
    cached_catalog = nil
    return
  end
  cached_catalog = build_catalog(entries, root or '/tmp/test-root')
end

---@class OfflineSchemaOpts
---@field select? string[] Mutually exclusive with `ignore`.
---@field ignore? string[] Mutually exclusive with `select`.
---@field replace? table<string, OfflineSchemaEntry|string>
---@field extra? OfflineSchemaEntry[] Caller is responsible for offline-safe URLs.

---@param value any
---@return boolean
local function is_nonempty_table(value) return type(value) == 'table' and not vim.tbl_isempty(value) end

---@param opts? OfflineSchemaOpts
---@return OfflineSchemaEntry[]
function M.json.schemas(opts)
  local catalog = load_catalog()
  if opts == nil then return catalog.schemas end

  local has_extra = is_nonempty_table(opts.extra)
  local has_replace = is_nonempty_table(opts.replace)
  local has_select = is_nonempty_table(opts.select)
  local has_ignore = is_nonempty_table(opts.ignore)
  if not (has_extra or has_replace or has_select or has_ignore) then return catalog.schemas end
  assert(
    not (has_select and has_ignore),
    "offline_schemas: 'select' and 'ignore' are mutually exclusive"
  )

  -- Work on owned copies so callers cannot mutate the module cache.
  local schemas = vim.deepcopy(catalog.schemas)
  local index = vim.deepcopy(catalog.index)

  if has_extra then
    -- Deepcopy on insert so a later `replace` (or a caller mutating opts.extra
    -- after the call) cannot reach back through the returned list.
    for _, extra_schema in ipairs(opts.extra) do
      local owned = vim.deepcopy(extra_schema)
      local existing_idx = index[owned.name]
      local idx = existing_idx or (#schemas + 1)
      schemas[idx] = owned
      index[owned.name] = idx
    end
  end

  if has_replace then
    for name, replacement in pairs(opts.replace) do
      local original, idx = find_in(schemas, index, name)
      assert(original ~= nil and idx ~= nil, 'offline_schemas: replace: schema not found: ' .. name)
      if type(replacement) == 'string' then
        original.url = replacement
      else
        assert(
          replacement.name == original.name,
          string.format(
            'offline_schemas: replace: replaced schema has different name: %s != %s',
            replacement.name,
            original.name
          )
        )
        schemas[idx] = replacement
      end
    end
  end

  if has_select then
    local selected = {}
    for _, name in ipairs(opts.select) do
      local schema = find_in(schemas, index, name)
      assert(schema ~= nil, 'offline_schemas: select: schema not found: ' .. name)
      table.insert(selected, schema)
    end
    return selected
  end

  if has_ignore then
    local indices = {}
    for _, name in ipairs(opts.ignore) do
      local _, idx = find_in(schemas, index, name)
      assert(idx ~= nil, 'offline_schemas: ignore: schema not found: ' .. name)
      table.insert(indices, idx)
    end
    table.sort(indices, function(a, b) return a > b end)
    for _, idx in ipairs(indices) do
      table.remove(schemas, idx)
    end
  end

  return schemas
end

---@param opts? OfflineSchemaOpts
---@return table<string, string|string[]>
function M.yaml.schemas(opts)
  local result = {}
  for _, entry in ipairs(M.json.schemas(opts)) do
    if entry.url ~= nil and entry.fileMatch ~= nil then result[entry.url] = entry.fileMatch end
  end
  return result
end

return M
