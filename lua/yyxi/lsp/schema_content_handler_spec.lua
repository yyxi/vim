local assert = require('luassert')
local handler_module = require('yyxi.lsp.schema_content_handler')
local offline_schemas = require('yyxi.utilities.offline_schemas')

local handler = handler_module.handler

describe('yyxi.lsp.schema_content_handler', function()
  it("returns '{}' for nil params", function() assert.equals('{}', handler(nil, nil, nil, nil)) end)

  it(
    "returns '{}' for non-string, non-table params",
    function() assert.equals('{}', handler(nil, 42, nil, nil)) end
  )

  it(
    "returns '{}' for URIs that aren't schemastore-hosted",
    function()
      assert.equals(
        '{}',
        handler(nil, 'https://raw.githubusercontent.com/some/repo/schema.json', nil, nil)
      )
    end
  )

  it('accepts a string URI', function()
    -- The URI does not resolve (no such schema vendored), so we expect '{}'.
    assert.equals('{}', handler(nil, 'https://www.schemastore.org/zzz-nonexistent.json', nil, nil))
  end)

  it(
    'accepts a table payload with .uri',
    function()
      assert.equals(
        '{}',
        handler(nil, { uri = 'https://www.schemastore.org/zzz-nonexistent.json' }, nil, nil)
      )
    end
  )

  it('returns the vendored schema body for a known schemastore URL', function()
    -- The catalog itself is loaded via the same path resolution under the
    -- hood; this exercises the end-to-end path.
    local resolved =
      offline_schemas.resolve_local_schema_path('https://www.schemastore.org/package.json')
    if resolved == nil then
      pending('package.json schema is not vendored on this host')
      return
    end
    local body = handler(nil, 'https://www.schemastore.org/package.json', nil, nil)
    assert.is_true(#body > 0)
    -- It must be a JSON document; just check it starts with `{`.
    assert.equals('{', body:sub(1, 1))
  end)
end)
