local assert = require('luassert')
local offline_schemas = require('yyxi.utilities.offline_schemas')
local overlay = require('yyxi.lsp.tombi_schema_overlay')

local fixture_entries = {
  {
    name = 'alpha.toml',
    description = 'Alpha',
    fileMatch = { 'alpha.toml', '.alpha.toml' },
    path = 'vendor/git/worktrees/schemastore/src/schemas/json/alpha.json',
  },
  {
    name = 'mixed.json',
    description = 'Has both JSON and TOML patterns',
    fileMatch = { 'mixed.json', 'mixed.toml', '.mixed.yml' },
    path = 'vendor/git/worktrees/schemastore/src/schemas/json/mixed.json',
  },
  {
    name = 'pure-json.json',
    description = 'No TOML patterns',
    fileMatch = { 'pure.json', '*.json' },
    path = 'vendor/git/worktrees/schemastore/src/schemas/json/pure-json.json',
  },
  {
    name = 'single-string.toml',
    description = 'fileMatch is a bare string',
    fileMatch = 'single.toml',
    path = 'vendor/git/worktrees/schemastore/src/schemas/json/single.json',
  },
  {
    name = 'glob.toml',
    description = 'Glob patterns must round-trip',
    fileMatch = { '**/*.toml', '**/conf.d/*.toml', '*.json' },
    path = 'vendor/git/worktrees/schemastore/src/schemas/json/glob.json',
  },
}

local function install_fixture() offline_schemas._set_catalog_for_tests(fixture_entries, '/repo') end

local function reset()
  offline_schemas._set_catalog_for_tests(nil)
  overlay._reset_for_tests()
end

local next_client_id = 0

---Build a stub client whose `:notify` records every call. Each call returns a
---client with a fresh id so the overlay's per-client dedup table doesn't bleed
---between tests.
---@return table
local function recording_client()
  next_client_id = next_client_id + 1
  local sent = {}
  local client = { id = next_client_id }
  function client:notify(method, params) table.insert(sent, { method = method, params = params }) end
  client._sent = sent
  return client
end

describe('yyxi.lsp.tombi_schema_overlay', function()
  before_each(install_fixture)
  after_each(reset)

  it('classifies patterns by .toml suffix (case-insensitive)', function()
    assert.is_true(overlay._is_toml_pattern('foo.toml'))
    assert.is_true(overlay._is_toml_pattern('FOO.TOML'))
    assert.is_true(overlay._is_toml_pattern('**/*.toml'))
    assert.is_false(overlay._is_toml_pattern('foo.json'))
    assert.is_false(overlay._is_toml_pattern('foo.toml.j2'))
    assert.is_false(overlay._is_toml_pattern(nil))
    assert.is_false(overlay._is_toml_pattern(42))
  end)

  it('returns the TOML-only subset, or nil if none', function()
    assert.same({ 'foo.toml' }, overlay._toml_subset({ 'foo.toml', 'foo.json' }))
    assert.same({ 'single.toml' }, overlay._toml_subset('single.toml'))
    assert.is_nil(overlay._toml_subset({ 'a.json', 'b.yml' }))
    assert.is_nil(overlay._toml_subset(nil))
    assert.is_nil(overlay._toml_subset('plain.json'))
  end)

  it('sends one tombi/associateSchema per TOML-bearing entry', function()
    local client = recording_client()
    local count = overlay.attach(client)
    -- 4 entries with at least one TOML pattern: alpha, mixed, single, glob.
    assert.equals(4, count)
    assert.equals(4, #client._sent)
    for _, sent in ipairs(client._sent) do
      assert.equals('tombi/associateSchema', sent.method)
      assert.is_string(sent.params.uri)
      assert.equals('file:', sent.params.uri:sub(1, 5))
      assert.is_table(sent.params.fileMatch)
      assert.is_true(#sent.params.fileMatch >= 1)
    end
  end)

  it('preserves glob patterns in the wire payload', function()
    local client = recording_client()
    overlay.attach(client)
    local glob_payload
    for _, sent in ipairs(client._sent) do
      if sent.params.uri:match('glob%.json$') then
        glob_payload = sent.params
        break
      end
    end
    assert.is_not_nil(glob_payload)
    assert.same({ '**/*.toml', '**/conf.d/*.toml' }, glob_payload.fileMatch)
  end)

  it('is idempotent across repeated attach calls for the same client', function()
    local client = recording_client()
    assert.equals(4, overlay.attach(client))
    assert.equals(0, overlay.attach(client))
    -- The recorded sends should not have grown on the second call.
    assert.equals(4, #client._sent)
  end)

  it('treats distinct clients independently', function()
    local first = recording_client()
    local second = recording_client()
    assert.equals(4, overlay.attach(first))
    assert.equals(4, overlay.attach(second))
  end)

  it('every notification carries a string uri', function()
    local client = recording_client()
    overlay.attach(client)
    for _, sent in ipairs(client._sent) do
      assert.is_string(sent.params.uri)
    end
  end)

  it('drops non-TOML patterns from mixed entries', function()
    local client = recording_client()
    overlay.attach(client)
    local mixed_payload
    for _, sent in ipairs(client._sent) do
      if sent.params.uri:match('mixed%.json$') then
        mixed_payload = sent.params
        break
      end
    end
    assert.is_not_nil(mixed_payload)
    assert.same({ 'mixed.toml' }, mixed_payload.fileMatch)
  end)

  it('handles bare-string fileMatch entries', function()
    local client = recording_client()
    overlay.attach(client)
    local found = false
    for _, sent in ipairs(client._sent) do
      if sent.params.uri:match('single%.json$') then
        assert.same({ 'single.toml' }, sent.params.fileMatch)
        found = true
      end
    end
    assert.is_true(found)
  end)

  it('omits entries with no TOML patterns', function()
    local client = recording_client()
    overlay.attach(client)
    for _, sent in ipairs(client._sent) do
      assert.is_nil(sent.params.uri:match('pure%-json'))
    end
  end)
end)
