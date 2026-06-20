local assert = require('luassert')
local offline_schemas = require('yyxi.utilities.offline_schemas')

local fixture_entries = {
  {
    name = 'alpha.json',
    description = 'Alpha schema',
    fileMatch = { '.alpha.json' },
    path = 'vendor/git/worktrees/schemastore/src/schemas/json/alpha.json',
  },
  {
    name = 'beta.json',
    description = 'Beta schema',
    fileMatch = '.beta.json',
    path = 'vendor/git/worktrees/schemastore/src/schemas/json/beta.json',
    versions = {
      ['1.0'] = 'vendor/git/worktrees/schemastore/src/schemas/json/beta-1.0.json',
    },
  },
}

local function install_fixture() offline_schemas._set_catalog_for_tests(fixture_entries, '/repo') end

local function reset() offline_schemas._set_catalog_for_tests(nil) end

describe('yyxi.utilities.offline_schemas', function()
  before_each(install_fixture)
  after_each(reset)

  it('rewrites relative paths into absolute file:// URLs', function()
    local alpha = assert(offline_schemas.json.get('alpha.json'))
    assert.equals(
      'file:///repo/vendor/git/worktrees/schemastore/src/schemas/json/alpha.json',
      alpha.url
    )
    local beta = assert(offline_schemas.json.get('beta.json'))
    assert.equals(
      'file:///repo/vendor/git/worktrees/schemastore/src/schemas/json/beta-1.0.json',
      assert(beta.versions)['1.0']
    )
  end)

  it('returns the cached schemas table by reference when no opts are passed', function()
    local a = offline_schemas.json.schemas()
    local b = offline_schemas.json.schemas()
    assert.is_true(rawequal(a, b))
  end)

  it('short-circuits when every filter is empty', function()
    local a = offline_schemas.json.schemas()
    local b = offline_schemas.json.schemas({ select = {}, ignore = {}, extra = {}, replace = {} })
    assert.is_true(rawequal(a, b))
  end)

  it('builds yaml schemas as url-keyed fileMatch entries', function()
    local yaml = offline_schemas.yaml.schemas()
    assert.equals(
      fixture_entries[1].fileMatch,
      yaml['file:///repo/vendor/git/worktrees/schemastore/src/schemas/json/alpha.json']
    )
    assert.equals(
      fixture_entries[2].fileMatch,
      yaml['file:///repo/vendor/git/worktrees/schemastore/src/schemas/json/beta.json']
    )
  end)

  it('select returns entries in the requested order', function()
    local result = offline_schemas.json.schemas({ select = { 'beta.json', 'alpha.json' } })
    assert.equals(2, #result)
    assert.equals('beta.json', result[1].name)
    assert.equals('alpha.json', result[2].name)
  end)

  it('ignore removes entries by name', function()
    local result = offline_schemas.json.schemas({ ignore = { 'beta.json' } })
    assert.equals(1, #result)
    assert.equals('alpha.json', result[1].name)
  end)

  it('select and ignore are mutually exclusive', function()
    assert.has_error(
      function()
        offline_schemas.json.schemas({ select = { 'alpha.json' }, ignore = { 'beta.json' } })
      end
    )
  end)

  it('select asserts on unknown names', function()
    assert.has_error(function() offline_schemas.json.schemas({ select = { 'missing' } }) end)
  end)

  it('ignore asserts on unknown names', function()
    assert.has_error(function() offline_schemas.json.schemas({ ignore = { 'missing' } }) end)
  end)

  it('extra appends new entries without mutating the cache', function()
    local extra = {
      name = 'gamma.json',
      description = 'Gamma schema',
      fileMatch = { '.gamma.json' },
      url = 'file:///tmp/gamma.json',
    }
    local result = offline_schemas.json.schemas({ extra = { extra } })
    assert.equals(3, #result)
    local cached = offline_schemas.json.schemas()
    assert.equals(2, #cached)
    -- Mutating the caller's extra table does not bleed into the previous return.
    extra.fileMatch = '.changed.json'
    assert.equals('.gamma.json', result[3].fileMatch[1])
  end)

  it('replace with a string swaps only the URL', function()
    local result = offline_schemas.json.schemas({
      replace = { ['alpha.json'] = 'file:///tmp/alpha-override.json' },
    })
    local alpha = result[1]
    assert.equals('alpha.json', alpha.name)
    assert.equals('file:///tmp/alpha-override.json', alpha.url)
    -- Cache is untouched.
    local cached = assert(offline_schemas.json.get('alpha.json'))
    assert.equals(
      'file:///repo/vendor/git/worktrees/schemastore/src/schemas/json/alpha.json',
      cached.url
    )
  end)

  it('replace with a table substitutes the entry when names match', function()
    local replacement = {
      name = 'alpha.json',
      description = 'Replaced',
      fileMatch = { 'replaced.json' },
      url = 'file:///tmp/alpha-replaced.json',
    }
    local result = offline_schemas.json.schemas({ replace = { ['alpha.json'] = replacement } })
    assert.equals('Replaced', result[1].description)
  end)

  it('replace asserts on name mismatch', function()
    assert.has_error(
      function()
        offline_schemas.json.schemas({
          replace = {
            ['alpha.json'] = {
              name = 'different',
              description = 'x',
              fileMatch = {},
              url = 'file:///tmp/x',
            },
          },
        })
      end
    )
  end)

  it('extra then replace with string mutates only the returned entry', function()
    local extra = {
      name = 'gamma.json',
      description = 'Gamma',
      fileMatch = { '.gamma.json' },
      url = 'file:///tmp/gamma.json',
    }
    local result = offline_schemas.json.schemas({
      extra = { extra },
      replace = { ['gamma.json'] = 'file:///tmp/gamma-override.json' },
    })
    assert.equals('file:///tmp/gamma-override.json', result[3].url)
    assert.equals('file:///tmp/gamma.json', extra.url)
  end)
end)
