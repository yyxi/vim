local assert = require('luassert')
local lean = require('yyxi.plugins.lean')
local treesitter = require('yyxi.utilities.treesitter')

describe('yyxi.plugins.lean', function()
  local buffer
  local previous_buffer

  before_each(function()
    treesitter.prepend_runtimepath()
    previous_buffer = vim.api.nvim_get_current_buf()
    buffer = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(buffer)
  end)

  after_each(function()
    if vim.api.nvim_buf_is_valid(previous_buffer) then
      vim.api.nvim_set_current_buf(previous_buffer)
    end
    if vim.api.nvim_buf_is_valid(buffer) then vim.api.nvim_buf_delete(buffer, { force = true }) end
  end)

  it('sets lightweight Lean file options and matchup expressions', function()
    lean.configure_buffer()

    assert.equals('-- %s', vim.bo[buffer].commentstring)
    assert.equals(2, vim.bo[buffer].shiftwidth)
    assert.equals(2, vim.bo[buffer].softtabstop)
    assert.is_true(vim.bo[buffer].expandtab)
    assert.matches('⟨:⟩', vim.bo[buffer].matchpairs, nil, true)
    assert.matches('\\<if\\>:\\<then\\>:\\<else\\>', vim.b[buffer].match_words)
    assert.matches('matchup_skip', vim.b[buffer].match_skip, nil, true)
    assert.matches(
      'unlet! b:match_ignorecase b:match_skip b:match_words',
      vim.b[buffer].undo_ftplugin
    )
  end)

  it('skips comments and strings but not Lean interpolation expressions', function()
    local lines = {
      '-- if then else',
      'def text := "if then else"',
      'def interpolated := s!"text {if True then 1 else 2}"',
      'if True then 1 else 2',
    }
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
    vim.bo[buffer].filetype = 'lean'
    vim.treesitter.start(buffer, 'lean')

    local function column(row, text) return _G.assert(lines[row + 1]:find(text, 1, true)) - 1 end

    assert.is_true(lean.matchup_skip(buffer, 0, column(0, 'if')))
    assert.is_true(lean.matchup_skip(buffer, 1, column(1, 'if')))
    assert.is_true(lean.matchup_skip(buffer, 2, column(2, 'text')))
    assert.is_false(lean.matchup_skip(buffer, 2, column(2, 'if')))
    assert.is_false(lean.matchup_skip(buffer, 3, column(3, 'if')))
  end)
end)
