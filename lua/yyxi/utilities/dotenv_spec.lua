local dotenv = require('yyxi.utilities.dotenv')

---@param lines string[]
---@return string
local function join(lines) return table.concat(lines, '\n') .. '\n' end

describe('yyxi.utilities.dotenv', function()
  it('parses assignments into the supplied environment', function()
    local env = {}

    local parsed = dotenv.parse(
      join({
        '# ignored',
        '',
        'ALPHA=one',
        'BETA="two"',
      }),
      env
    )

    assert.same({ ALPHA = 'one', BETA = 'two' }, parsed)
    assert.same(parsed, env)
  end)

  it('preserves equals signs inside values', function()
    local parsed = dotenv.parse('TOKEN=a=b=c\n', {})

    assert.equals('a=b=c', parsed.TOKEN)
  end)

  it('lets later files override earlier files', function()
    local first = vim.fn.tempname()
    local second = vim.fn.tempname()
    vim.fn.writefile({ 'VALUE=first', 'KEEP=yes' }, first)
    vim.fn.writefile({ 'VALUE=second' }, second)

    local env = {}
    local loaded = dotenv.load_files({ first, second }, env)

    vim.fn.delete(first)
    vim.fn.delete(second)

    assert.same({ VALUE = 'second', KEEP = 'yes' }, loaded)
    assert.same(loaded, env)
  end)

  it('returns an empty table for a missing file', function()
    local env = {}

    local loaded = dotenv.load('/missing/dotenv/file', env)

    assert.same({}, loaded)
    assert.same({}, env)
  end)
end)
