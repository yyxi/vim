local assert = require('luassert')

local function load_module()
  package.loaded['yyxi.plugins.telescope_fff'] = nil
  return require('yyxi.plugins.telescope_fff')
end

describe('yyxi.plugins.telescope_fff', function()
  after_each(function() package.loaded['yyxi.plugins.telescope_fff'] = nil end)

  it('maps file and grep results into Telescope-compatible line formats', function()
    local telescope_fff = load_module()

    assert.same(
      { 'lua/yyxi/plugins/interface.lua' },
      telescope_fff._file_search_lines({
        items = {
          { relative_path = 'lua/yyxi/plugins/interface.lua' },
        },
      })
    )

    assert.same(
      { 'lua/yyxi/plugins/interface.lua:17:4:needle' },
      telescope_fff._grep_result_lines({
        items = {
          {
            col = 3,
            line_content = 'needle',
            line_number = 17,
            relative_path = 'lua/yyxi/plugins/interface.lua',
          },
        },
      })
    )
  end)

  it('uses regex for live_grep-style searches and plain mode for grep_string by default', function()
    local telescope_fff = load_module()

    assert.equals('plain', telescope_fff._grep_mode_for_grep_string())
    assert.equals('plain', telescope_fff._grep_mode_for_grep_string({}))
    assert.equals('regex', telescope_fff._grep_mode_for_grep_string({ use_regex = true }))
  end)

  it('builds FFF and Telescope request tables directly from picker options', function()
    local telescope_fff = load_module()

    assert.same({
      cwd = vim.fn.fnamemodify(vim.fn.expand('/tmp/example'), ':p'),
      max_results = 25,
      mode = 'files',
      wait_for_index_ms = 10000,
    }, telescope_fff.file_search_request({ cwd = '/tmp/example', max_results = 25 }))

    assert.same({
      cwd = vim.fn.fnamemodify(vim.fn.expand('/tmp/example'), ':p'),
      mode = 'regex',
      page_size = 33,
      wait_for_index_ms = 10000,
    }, telescope_fff.content_search_request('regex', { cwd = '/tmp/example', page_size = 33 }))

    assert.same({
      cwd = vim.fn.fnamemodify(vim.fn.expand('/tmp/example'), ':p'),
      hidden = true,
    }, telescope_fff.telescope_picker_opts({ cwd = '/tmp/example', hidden = true }))
  end)

  it('classifies unsupported Telescope options explicitly', function()
    local telescope_fff = load_module()

    assert.is_true(telescope_fff.find_files_unsupported({ hidden = true }))
    assert.is_false(telescope_fff.find_files_unsupported({ cwd = '/tmp/example' }))

    assert.is_true(telescope_fff.live_grep_unsupported({ additional_args = { '--hidden' } }))
    assert.is_false(telescope_fff.live_grep_unsupported({ cwd = '/tmp/example' }))

    assert.is_true(telescope_fff.grep_string_unsupported({ word_match = '-w' }))
    assert.is_false(telescope_fff.grep_string_unsupported({ search = 'needle' }))
  end)

  it('exposes directly testable FFF search helpers without Telescope stubs', function()
    local telescope_fff = load_module()
    local calls = {}
    local fff = {
      file_search = function(query, request)
        table.insert(calls, { kind = 'file', query = query, request = request })
        return { items = { { relative_path = 'lua/yyxi/plugins/interface.lua' } } }
      end,
      content_search = function(query, request)
        table.insert(calls, { kind = 'content', query = query, request = request })
        return {
          items = {
            {
              col = 2,
              line_content = 'match text',
              line_number = 9,
              relative_path = 'lua/yyxi/plugins/interface.lua',
            },
          },
        }
      end,
    }

    local file_lines =
      telescope_fff.find_files_searcher(fff, { cwd = '/tmp/repo', max_results = 10 })('needle')
    local grep_lines =
      telescope_fff.live_grep_searcher(fff, { cwd = '/tmp/repo', page_size = 20 })('pattern')
    local grep_string_lines = telescope_fff.grep_string_lines(fff, 'literal', { cwd = '/tmp/repo' })

    assert.same({ 'lua/yyxi/plugins/interface.lua' }, file_lines)
    assert.same({ 'lua/yyxi/plugins/interface.lua:9:3:match text' }, grep_lines)
    assert.same({ 'lua/yyxi/plugins/interface.lua:9:3:match text' }, grep_string_lines)

    assert.same('file', calls[1].kind)
    assert.same('needle', calls[1].query)
    assert.same('files', calls[1].request.mode)
    assert.equals(10, calls[1].request.max_results)

    assert.same('content', calls[2].kind)
    assert.same('pattern', calls[2].query)
    assert.same('regex', calls[2].request.mode)
    assert.equals(20, calls[2].request.page_size)

    assert.same('content', calls[3].kind)
    assert.same('literal', calls[3].query)
    assert.same('plain', calls[3].request.mode)
  end)

  it('uses a cheap health check instead of a probe query to resolve the backend', function()
    local telescope_fff = load_module()
    local search_calls = 0
    local fff = {
      file_search = function()
        search_calls = search_calls + 1
        return { items = {} }
      end,
    }

    ---@diagnostic disable-next-line: duplicate-set-field
    telescope_fff._load_fff = function() return true, fff end
    ---@diagnostic disable-next-line: duplicate-set-field
    telescope_fff._prepare_fff_runtime = function() end
    ---@diagnostic disable-next-line: duplicate-set-field
    telescope_fff.fff_health_ok = function(opts)
      assert.same({ cwd = '/tmp/repo' }, opts)
      return true
    end

    local resolved = telescope_fff.resolve_fff_backend({ cwd = '/tmp/repo' })

    assert.same(fff, resolved)
    assert.equals(0, search_calls)
  end)
end)
