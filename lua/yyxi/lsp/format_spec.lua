local assert = require('luassert')

-- Stub `conform` before requiring the module under test so the recorder is in
-- place at first load. Each test resets the recorder + reloads the module.
local recorded_calls = {}
local stubbed_conform = {
  format = function(opts, callback)
    table.insert(recorded_calls, { opts = opts, callback = callback })
    return true
  end,
}

local function load_module_with_stub()
  package.loaded['conform'] = stubbed_conform
  package.loaded['yyxi.lsp.format'] = nil
  local format = require('yyxi.lsp.format')
  -- Default test config: every TOML test in this file expects the canonical
  -- tombi → eslint order. The unordered/setup-driven tests override or skip.
  format.setup({ toml = { order = { 'tombi', 'eslint' } } })
  return format
end

local function reset_recorded()
  -- Mutate in place rather than reassign so we don't rely on the
  -- recorded_calls upvalue being shared between `reset_recorded` and the
  -- stubbed `conform.format` closure. Future refactors that split these
  -- across modules would silently lose the binding.
  for key in pairs(recorded_calls) do
    recorded_calls[key] = nil
  end
end

local function full_reset()
  reset_recorded()
  if package.loaded['yyxi.lsp.format'] then require('yyxi.lsp.format')._reset_for_tests() end
end

local function in_buffer(filetype, fn)
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.bo[bufnr].filetype = filetype
  vim.api.nvim_set_current_buf(bufnr)
  local ok, err = pcall(fn, bufnr)
  if vim.api.nvim_buf_is_valid(bufnr) then vim.api.nvim_buf_delete(bufnr, { force = true }) end
  if not ok then error(err) end
end

describe('yyxi.lsp.format', function()
  before_each(full_reset)

  it('runs a single conform.format call for unordered filetypes', function()
    local format = load_module_with_stub()
    in_buffer('lua', function(bufnr)
      format.run()
      assert.equals(1, #recorded_calls)
      local opts = recorded_calls[1].opts
      assert.is_true(opts.async)
      assert.equals(bufnr, opts.bufnr)
      assert.equals('first', opts.lsp_format)
      assert.is_nil(opts.filter)
    end)
  end)

  it('takes the unordered branch when no setup config covers the filetype', function()
    -- Reload without the default test config so toml falls through.
    package.loaded['conform'] = stubbed_conform
    package.loaded['yyxi.lsp.format'] = nil
    local format = require('yyxi.lsp.format')
    in_buffer('toml', function()
      format.run()
      assert.equals(1, #recorded_calls)
      assert.equals('first', recorded_calls[1].opts.lsp_format)
      assert.is_nil(recorded_calls[1].opts.filter)
    end)
  end)

  it('setup() merges into existing config rather than replacing it', function()
    local format = load_module_with_stub()
    -- Default already registers toml. Add a new filetype and confirm both stick.
    format.setup({ yaml = { order = { 'yamlls' } } })
    in_buffer('yaml', function()
      format.run()
      assert.equals(1, #recorded_calls)
      assert.is_true(recorded_calls[1].opts.filter({ name = 'yamlls' }))
    end)
    -- And toml is still in place.
    reset_recorded()
    in_buffer('toml', function()
      format.run()
      assert.is_function(recorded_calls[1].opts.filter)
      assert.is_true(recorded_calls[1].opts.filter({ name = 'tombi' }))
    end)
  end)

  it('fires the first step immediately for toml buffers', function()
    local format = load_module_with_stub()
    in_buffer('toml', function(bufnr)
      format.run()
      assert.equals(1, #recorded_calls)
      local opts = recorded_calls[1].opts
      assert.is_true(opts.async)
      assert.is_true(opts.quiet)
      assert.equals(bufnr, opts.bufnr)
      assert.equals('prefer', opts.lsp_format)
      -- Each step explicitly disables CLI formatters so a future addition to
      -- `formatters_by_ft.toml` won't run once per chain step.
      assert.same({}, opts.formatters)
      assert.is_function(opts.filter)
      assert.is_true(opts.filter({ name = 'tombi' }))
      assert.is_false(opts.filter({ name = 'eslint' }))
    end)
  end)

  it('advances the chain when the first step callback fires', function()
    local format = load_module_with_stub()
    in_buffer('toml', function()
      format.run()
      assert.equals(1, #recorded_calls)
      recorded_calls[1].callback()
      assert.equals(2, #recorded_calls)
      assert.is_true(recorded_calls[2].opts.filter({ name = 'eslint' }))
      assert.is_false(recorded_calls[2].opts.filter({ name = 'tombi' }))
    end)
  end)

  it('advances even when a step reports an error (filter matched nothing)', function()
    local format = load_module_with_stub()
    in_buffer('toml', function()
      format.run()
      recorded_calls[1].callback('No formatters available for buffer', false)
      assert.equals(2, #recorded_calls)
    end)
  end)

  it('finalizes with a CLI-only conform call after the last LSP step', function()
    local format = load_module_with_stub()
    in_buffer('toml', function(bufnr)
      format.run()
      recorded_calls[1].callback() -- tombi → eslint
      recorded_calls[2].callback() -- eslint → finalize
      assert.equals(3, #recorded_calls)
      local finalize_opts = recorded_calls[3].opts
      assert.equals(bufnr, finalize_opts.bufnr)
      assert.equals('never', finalize_opts.lsp_format)
      assert.is_true(finalize_opts.quiet)
      assert.is_nil(finalize_opts.filter)
      assert.is_nil(finalize_opts.formatters)
      -- The chain ends after the finalize callback; no further calls.
      recorded_calls[3].callback()
      assert.equals(3, #recorded_calls)
    end)
  end)

  it('aborts further steps when the buffer becomes invalid', function()
    local format = load_module_with_stub()
    local outer_bufnr = vim.api.nvim_create_buf(false, true)
    vim.bo[outer_bufnr].filetype = 'toml'
    vim.api.nvim_set_current_buf(outer_bufnr)
    format.run()
    assert.equals(1, #recorded_calls)
    vim.api.nvim_buf_delete(outer_bufnr, { force = true })
    recorded_calls[1].callback()
    assert.equals(1, #recorded_calls)
    -- Re-entry guard must be cleared after the abort, so a fresh run on a new
    -- toml buffer kicks off a new chain (rather than no-oping forever).
    in_buffer('toml', function()
      format.run()
      assert.equals(2, #recorded_calls)
    end)
  end)

  it('skips the CLI finalize and clears the guard when buffer dies last', function()
    local format = load_module_with_stub()
    local outer_bufnr = vim.api.nvim_create_buf(false, true)
    vim.bo[outer_bufnr].filetype = 'toml'
    vim.api.nvim_set_current_buf(outer_bufnr)
    format.run()
    recorded_calls[1].callback() -- tombi → eslint
    recorded_calls[2].callback() -- eslint → finalize_cli early-return branch
    -- Buffer is still valid here; finalize_cli scheduled a third call.
    assert.equals(3, #recorded_calls)
    vim.api.nvim_buf_delete(outer_bufnr, { force = true })
    -- After the finalize callback fires the in_flight guard is cleared even
    -- though the buffer died; verify by kicking off a new chain on a fresh
    -- toml buffer.
    recorded_calls[3].callback()
    in_buffer('toml', function()
      format.run()
      assert.equals(4, #recorded_calls)
    end)
  end)

  it('threads the range argument through every step', function()
    local format = load_module_with_stub()
    in_buffer('toml', function()
      local range = { start = { 1, 0 }, ['end'] = { 5, 0 } }
      format.run(range)
      assert.same(range, recorded_calls[1].opts.range)
      recorded_calls[1].callback()
      assert.same(range, recorded_calls[2].opts.range)
    end)
  end)

  it('rejects re-entry while a chain is in flight for the same buffer', function()
    local format = load_module_with_stub()
    in_buffer('toml', function()
      format.run()
      format.run()
      -- Second invocation must be a no-op; only one step has been kicked off.
      assert.equals(1, #recorded_calls)
      -- Drain the first chain (tombi → eslint → finalize), then a fresh
      -- invocation must work.
      recorded_calls[1].callback()
      recorded_calls[2].callback()
      recorded_calls[3].callback()
      format.run()
      assert.equals(4, #recorded_calls)
    end)
  end)
end)
