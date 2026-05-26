local assert = require('luassert')

local function load_fix()
  package.loaded['yyxi.lsp.fix'] = nil
  return require('yyxi.lsp.fix')
end

---@param tbl table
---@param key string
---@param value any
---@param stubs table[]
local function stub(tbl, key, value, stubs)
  table.insert(stubs, { tbl = tbl, key = key, value = tbl[key] })
  tbl[key] = value
end

---@class yyxi.lsp.fix_spec.FakeClientOptions
---@field supports_method? fun(method: string): boolean
---@field offset_encoding? string

---@param name string
---@param request_sync? fun(method: string, params: table, timeout_ms?: integer, bufnr?: integer): any, any?
---@param opts? yyxi.lsp.fix_spec.FakeClientOptions
local function fake_client(name, request_sync, opts)
  local client = {
    name = name,
    offset_encoding = opts and opts.offset_encoding or 'utf-16',
  }

  function client:request_sync(method, params, timeout_ms, bufnr)
    if request_sync then return request_sync(method, params, timeout_ms, bufnr) end
    return { err = nil, result = {} }
  end

  function client:supports_method(method)
    if opts and opts.supports_method then return opts.supports_method(method) end
    return true
  end

  return client
end

describe('yyxi.lsp.fix', function()
  local stubs
  local current_bufnr
  local current_filetype
  local current_changedtick
  local current_line_count
  local clients
  local notify_calls
  local echo_calls
  local applied_edits
  local apply_workspace_edit_hook

  before_each(function()
    stubs = {}
    current_bufnr = 11
    current_filetype = 'python'
    current_changedtick = 1
    current_line_count = 3
    clients = {}
    notify_calls = 0
    echo_calls = 0
    applied_edits = {}
    apply_workspace_edit_hook = nil

    stub(vim.api, 'nvim_get_current_buf', function() return current_bufnr end, stubs)
    stub(vim.api, 'nvim_get_option_value', function(name, opts)
      assert.equals('filetype', name)
      assert.equals(current_bufnr, opts.buf)
      return current_filetype
    end, stubs)
    stub(vim.api, 'nvim_buf_get_changedtick', function(bufnr)
      assert.equals(current_bufnr, bufnr)
      return current_changedtick
    end, stubs)
    stub(vim.api, 'nvim_buf_line_count', function(bufnr)
      assert.equals(current_bufnr, bufnr)
      return current_line_count
    end, stubs)
    stub(vim.lsp, 'get_clients', function(opts)
      assert.equals(current_bufnr, opts.bufnr)
      return clients
    end, stubs)
    stub(vim.lsp.util, 'make_text_document_params', function(bufnr)
      assert.equals(current_bufnr, bufnr)
      return { uri = 'file:///buffer/11' }
    end, stubs)
    stub(
      vim.lsp.util,
      '_make_line_range_params',
      function(bufnr, start_line, end_line, offset_encoding)
        assert.equals(current_bufnr, bufnr)
        assert.equals(0, start_line)
        assert.equals(current_line_count - 1, end_line)
        assert.equals('utf-16', offset_encoding)
        return {
          start = { line = 0, character = 0 },
          ['end'] = { line = current_line_count - 1, character = 0 },
        }
      end,
      stubs
    )
    stub(vim.lsp.util, 'apply_workspace_edit', function(edit, offset_encoding)
      assert.equals('utf-16', offset_encoding)
      table.insert(applied_edits, edit)
      if apply_workspace_edit_hook then apply_workspace_edit_hook(edit) end
    end, stubs)
    stub(vim, 'notify', function() notify_calls = notify_calls + 1 end, stubs)
    stub(vim.api, 'nvim_echo', function() echo_calls = echo_calls + 1 end, stubs)
  end)

  after_each(function()
    for index = #stubs, 1, -1 do
      local entry = stubs[index]
      entry.tbl[entry.key] = entry.value
    end

    package.loaded['yyxi.lsp.fix'] = nil
  end)

  it('matches filetypes exactly instead of splitting dotted filetypes', function()
    local fix = load_fix()
    local calls = {}
    current_filetype = 'yaml.ansible'
    clients = { fake_client('eslint') }

    fix.setup({
      yaml = {
        order = { 'eslint' },
      },
    })
    fix.register('eslint', {
      function()
        table.insert(calls, 'eslint')
        return { status = 'applied', changed = true }
      end,
    })

    local result = fix.fix()

    assert.same({}, calls)
    assert.equals('skipped', result.status)
    assert.equals(1, result.skipped_count)
  end)

  it('uses explicit dotted filetype entries', function()
    local fix = load_fix()
    local calls = {}
    current_filetype = 'yaml.ansible'
    clients = { fake_client('eslint') }

    fix.setup({
      ['yaml.ansible'] = {
        order = { 'eslint' },
      },
    })
    fix.register('eslint', {
      function()
        table.insert(calls, 'eslint')
        return { status = 'noop', changed = false }
      end,
    })

    local result = fix.fix()

    assert.same({ 'eslint' }, calls)
    assert.equals('noop', result.status)
    assert.equals(1, result.noop_count)
  end)

  it('runs top-level AND steps left to right', function()
    local fix = load_fix()
    local calls = {}
    clients = {
      fake_client('pyright'),
      fake_client('ruff'),
    }

    fix.setup({
      python = {
        order = { 'pyright', 'ruff' },
      },
    })
    fix.register('pyright', {
      function()
        table.insert(calls, 'pyright')
        return { status = 'noop', changed = false }
      end,
    })
    fix.register('ruff', {
      function()
        table.insert(calls, 'ruff')
        return { status = 'applied', changed = true }
      end,
    })

    local result = fix.fix()

    assert.same({ 'pyright', 'ruff' }, calls)
    assert.equals('applied', result.status)
    assert.equals(1, result.applied_count)
    assert.equals(1, result.noop_count)
  end)

  it('stops OR groups on noop and continues to the next AND step', function()
    local fix = load_fix()
    local calls = {}
    clients = {
      fake_client('ty'),
      fake_client('pyright'),
      fake_client('ruff'),
    }

    fix.setup({
      python = {
        order = {
          { 'ty', 'pyright' },
          'ruff',
        },
      },
    })
    fix.register('ty', {
      function()
        table.insert(calls, 'ty')
        return { status = 'noop', changed = false }
      end,
    })
    fix.register('pyright', {
      function()
        table.insert(calls, 'pyright')
        return { status = 'applied', changed = true }
      end,
    })
    fix.register('ruff', {
      function()
        table.insert(calls, 'ruff')
        return { status = 'noop', changed = false }
      end,
    })

    local result = fix.fix()

    assert.same({ 'ty', 'ruff' }, calls)
    assert.equals('noop', result.status)
    assert.equals(2, result.noop_count)
  end)

  it('continues OR groups across skipped and failed results', function()
    local fix = load_fix()
    local calls = {}
    clients = {
      fake_client('pyright'),
      fake_client('ruff'),
    }

    fix.setup({
      python = {
        order = {
          { 'ty', 'pyright' },
          'ruff',
        },
      },
    })
    fix.register('pyright', {
      function()
        table.insert(calls, 'pyright')
        return { status = 'failed', changed = false }
      end,
    })
    fix.register('ruff', {
      function()
        table.insert(calls, 'ruff')
        return { status = 'applied', changed = true }
      end,
    })

    local result = fix.fix()

    assert.same({ 'pyright', 'ruff' }, calls)
    assert.equals('applied', result.status)
    assert.equals(1, result.applied_count)
    assert.equals(1, result.failed_count)
  end)

  it('skips attached clients without registered handlers and stale names quietly', function()
    local fix = load_fix()
    local calls = {}
    clients = {
      fake_client('ty'),
      fake_client('ruff'),
    }

    fix.setup({
      python = {
        order = { 'ghost', 'ty', 'ruff' },
      },
    })
    fix.register('ruff', {
      function()
        table.insert(calls, 'ruff')
        return { status = 'applied', changed = true }
      end,
    })

    local result = fix.fix()

    assert.same({ 'ruff' }, calls)
    assert.equals('applied', result.status)
    assert.equals(1, result.applied_count)
    assert.equals(2, result.skipped_count)
  end)

  it('runs all handlers for a client even when one fails', function()
    local fix = load_fix()
    local calls = {}
    clients = { fake_client('ruff') }

    fix.setup({
      python = {
        order = { 'ruff' },
      },
    })
    fix.register('ruff', {
      function()
        table.insert(calls, 'first')
        error('boom')
      end,
      function()
        table.insert(calls, 'second')
        return { status = 'applied', changed = true }
      end,
    })

    local result = fix.fix()

    assert.same({ 'first', 'second' }, calls)
    assert.equals('applied', result.status)
    assert.equals(1, result.applied_count)
    assert.equals(1, result.failed_count)
  end)

  it('classifies workspace command success by changedtick movement', function()
    local fix = load_fix()
    local client = fake_client('eslint', function(method, params, timeout_ms, bufnr)
      assert.equals('workspace/executeCommand', method)
      assert.same({ command = 'eslint.applyAllFixes', arguments = { 'buffer' } }, params)
      assert.equals(3000, timeout_ms)
      assert.equals(current_bufnr, bufnr)
      current_changedtick = current_changedtick + 1
      return { err = nil, result = {} }
    end)

    local applied = fix.execute_workspace_command({ bufnr = current_bufnr, client = client }, {
      command = 'eslint.applyAllFixes',
      arguments = { 'buffer' },
    }, 3000)

    assert.equals('applied', applied.status)
    assert.is_true(applied.changed)

    local noop = fix.execute_workspace_command(
      { bufnr = current_bufnr, client = fake_client('eslint') },
      {
        command = 'eslint.applyAllFixes',
        arguments = { 'buffer' },
      },
      3000
    )

    assert.equals('noop', noop.status)
    assert.is_false(noop.changed)
  end)

  it('classifies workspace command failures and remains quiet', function()
    local fix = load_fix()

    local timeout = fix.execute_workspace_command({
      bufnr = current_bufnr,
      client = fake_client('eslint', function() return nil, 'timeout' end),
    }, {
      command = 'eslint.applyAllFixes',
      arguments = {},
    }, 3000)

    assert.equals('failed', timeout.status)
    assert.is_false(timeout.changed)

    local thrown = fix.execute_workspace_command({
      bufnr = current_bufnr,
      client = fake_client('eslint', function() error('explode') end),
    }, {
      command = 'eslint.applyAllFixes',
      arguments = {},
    }, 3000)

    assert.equals('failed', thrown.status)
    assert.is_false(thrown.changed)
    assert.equals(0, notify_calls)
    assert.equals(0, echo_calls)
  end)

  it('executes whole-file code action kinds with workspace edits', function()
    local fix = load_fix()
    apply_workspace_edit_hook = function() current_changedtick = current_changedtick + 1 end

    local client = fake_client('gopls', function(method, params, timeout_ms, bufnr)
      assert.equals(current_bufnr, bufnr)
      assert.equals(3000, timeout_ms)

      if method == 'textDocument/codeAction' then
        assert.same({
          textDocument = { uri = 'file:///buffer/11' },
          range = {
            start = { line = 0, character = 0 },
            ['end'] = { line = current_line_count - 1, character = 0 },
          },
          context = {
            only = { 'source.fixAll' },
            diagnostics = {},
          },
        }, params)

        return {
          err = nil,
          result = {
            {
              title = 'Fix all',
              edit = {
                changes = {
                  ['file:///buffer/11'] = {},
                },
              },
            },
          },
        }
      end

      error('unexpected method: ' .. method)
    end)

    local applied = fix.execute_code_action_kind(
      { bufnr = current_bufnr, client = client },
      'source.fixAll',
      3000
    )

    assert.equals('applied', applied.status)
    assert.is_true(applied.changed)
    assert.same({
      {
        changes = {
          ['file:///buffer/11'] = {},
        },
      },
    }, applied_edits)
  end)

  it('passes explicit diagnostics to code action requests', function()
    local fix = load_fix()
    local diagnostics = {
      {
        range = {
          start = { line = 0, character = 0 },
          ['end'] = { line = 0, character = 3 },
        },
        message = 'simplify range expression',
      },
    }

    local client = fake_client('gopls', function(method, params, timeout_ms, bufnr)
      assert.equals(current_bufnr, bufnr)
      assert.equals(3000, timeout_ms)

      if method == 'textDocument/codeAction' then
        assert.same(diagnostics, params.context.diagnostics)
        return { err = nil, result = {} }
      end

      error('unexpected method: ' .. method)
    end)

    local skipped = fix.execute_code_action_kind(
      { bufnr = current_bufnr, client = client },
      'source.fixAll',
      3000,
      diagnostics
    )

    assert.equals('skipped', skipped.status)
    assert.is_false(skipped.changed)
  end)

  it('executes command-only code action results', function()
    local fix = load_fix()
    local client = fake_client('gopls', function(method, params, timeout_ms, bufnr)
      assert.equals(current_bufnr, bufnr)
      assert.equals(3000, timeout_ms)

      if method == 'textDocument/codeAction' then
        return {
          err = nil,
          result = {
            {
              title = 'Organize imports',
              command = 'gopls.organize_imports',
              arguments = { 'buffer' },
            },
          },
        }
      end

      if method == 'workspace/executeCommand' then
        assert.same({
          title = 'Organize imports',
          command = 'gopls.organize_imports',
          arguments = { 'buffer' },
        }, params)
        current_changedtick = current_changedtick + 1
        return { err = nil, result = {} }
      end

      error('unexpected method: ' .. method)
    end)

    local applied = fix.execute_code_action_kind(
      { bufnr = current_bufnr, client = client },
      'source.organizeImports',
      3000
    )

    assert.equals('applied', applied.status)
    assert.is_true(applied.changed)
  end)

  it('classifies empty and no-op code action results', function()
    local fix = load_fix()

    local skipped = fix.execute_code_action_kind({
      bufnr = current_bufnr,
      client = fake_client('gopls', function(method)
        assert.equals('textDocument/codeAction', method)
        return { err = nil, result = {} }
      end),
    }, 'source.fixAll', 3000)

    assert.equals('skipped', skipped.status)
    assert.is_false(skipped.changed)

    local noop = fix.execute_code_action_kind({
      bufnr = current_bufnr,
      client = fake_client('gopls', function(method)
        assert.equals('textDocument/codeAction', method)
        return {
          err = nil,
          result = {
            {
              title = 'Fix all',
              edit = {
                changes = {
                  ['file:///buffer/11'] = {},
                },
              },
            },
          },
        }
      end),
    }, 'source.fixAll', 3000)

    assert.equals('noop', noop.status)
    assert.is_false(noop.changed)
  end)

  it('classifies code action failures and remains quiet', function()
    local fix = load_fix()

    local unsupported = fix.execute_code_action_kind({
      bufnr = current_bufnr,
      client = fake_client('gopls', nil, {
        supports_method = function(method) return method ~= 'textDocument/codeAction' end,
      }),
    }, 'source.fixAll', 3000)

    assert.equals('skipped', unsupported.status)
    assert.is_false(unsupported.changed)

    local timeout = fix.execute_code_action_kind({
      bufnr = current_bufnr,
      client = fake_client('gopls', function() return nil, 'timeout' end),
    }, 'source.fixAll', 3000)

    assert.equals('failed', timeout.status)
    assert.is_false(timeout.changed)

    local bad_edit = fix.execute_code_action_kind({
      bufnr = current_bufnr,
      client = fake_client('gopls', function(method)
        assert.equals('textDocument/codeAction', method)
        return {
          err = nil,
          result = {
            {
              title = 'Fix all',
              edit = {
                changes = {},
              },
            },
          },
        }
      end),
    }, 'source.fixAll', 3000)

    assert.equals('noop', bad_edit.status)
    assert.is_false(bad_edit.changed)

    stub(vim.lsp.util, 'apply_workspace_edit', function() error('explode') end, stubs)

    local thrown = fix.execute_code_action_kind({
      bufnr = current_bufnr,
      client = fake_client('gopls', function(method)
        assert.equals('textDocument/codeAction', method)
        return {
          err = nil,
          result = {
            {
              title = 'Fix all',
              edit = {
                changes = {},
              },
            },
          },
        }
      end),
    }, 'source.fixAll', 3000)

    assert.equals('failed', thrown.status)
    assert.is_false(thrown.changed)
    assert.equals(0, notify_calls)
    assert.equals(0, echo_calls)
  end)
end)
