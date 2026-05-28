local assert = require('luassert')
local dotenv = require('yyxi.utilities.dotenv')

---@param lines string[]
---@return string
local function join(lines) return table.concat(lines, '\n') .. '\n' end

---@param lines string[]
---@return string
local function temp_file(lines)
  local path = vim.fn.tempname()
  vim.fn.mkdir(vim.fs.dirname(path), 'p')
  assert.equals(0, vim.fn.writefile(lines, path))
  return path
end

---@param root string
---@param relative_path string
---@param lines string[]
local function write_file(root, relative_path, lines)
  local path = vim.fs.joinpath(root, relative_path)
  vim.fn.mkdir(vim.fs.dirname(path), 'p')
  assert.equals(0, vim.fn.writefile(lines, path))
end

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
    local first = temp_file({ 'VALUE=first', 'KEEP=yes' })
    local second = temp_file({ 'VALUE=second' })

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

  it('loads default repository dotenv files from the provided root', function()
    local root = vim.fn.tempname()
    vim.fn.mkdir(root, 'p')
    write_file(root, '.env', { 'ALPHA=one', 'SHARED=base' })
    write_file(root, '.env.local', { 'BETA=two', 'SHARED=local' })

    local env = {}
    local loaded = dotenv.load_defaults(root, env)

    vim.fn.delete(root, 'rf')

    assert.same({ ALPHA = 'one', BETA = 'two', SHARED = 'local' }, loaded)
    assert.same(loaded, env)
  end)
end)
