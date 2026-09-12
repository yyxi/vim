local assert = require('luassert')
local treesitter = require('yyxi.utilities.treesitter')

describe('managed Lean Tree-sitter runtime', function()
  local runtimepath
  local foldmethod
  local foldexpr
  local buffer

  before_each(function()
    runtimepath = vim.opt.runtimepath:get()
    foldmethod = vim.wo.foldmethod
    foldexpr = vim.wo.foldexpr
    treesitter.prepend_runtimepath()
    buffer = vim.api.nvim_create_buf(false, true)
  end)

  after_each(function()
    vim.api.nvim_buf_delete(buffer, { force = true })
    vim.opt.runtimepath = runtimepath
    vim.wo.foldmethod = foldmethod
    vim.wo.foldexpr = foldexpr
  end)

  it('uses the managed lean parser for .lean files', function()
    local filetype = _G.assert(vim.filetype.match({ filename = 'Example.lean' }))

    assert.equals('lean', filetype)
    assert.equals('lean', vim.treesitter.language.get_lang(filetype))
    assert.is_true(vim.tbl_contains(treesitter.languages(), 'lean'))
    assert.is_true(treesitter.has_parser('lean'))
  end)

  it('loads the bundled editor queries', function()
    for _, kind in ipairs({ 'highlights', 'injections', 'indents', 'folds', 'locals' }) do
      assert.is_not_nil(vim.treesitter.query.get('lean', kind))
      assert.same(
        { vim.fs.joinpath(treesitter.site_dir(), 'queries', 'lean', kind .. '.scm') },
        vim.treesitter.query.get_files('lean', kind)
      )
    end
  end)

  it('parses Unicode, nested comments, and tactics with Markdown doc injections', function()
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, {
      '/-- An **identity** theorem. -/',
      'theorem identity (α : Type) (x : α) : x = x := by',
      '  /- outer /- nested -/ comment -/',
      '  rfl',
    })
    vim.bo[buffer].filetype = 'lean'
    treesitter.start_for_buffer({ buf = buffer })

    local parser = _G.assert(vim.treesitter.get_parser(buffer, 'lean'))
    local parsed = _G.assert(parser:parse(true))

    assert.is_false(parsed[1]:root():has_error())
    assert.is_not_nil(parser:children().markdown)
    assert.is_not_nil(vim.treesitter.highlighter.active[buffer])
    assert.equals(
      "v:lua.require'yyxi.utilities.treesitter'.indentexpr()",
      vim.bo[buffer].indentexpr
    )
  end)

  it('recovers after an incomplete declaration is repaired', function()
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { 'def value :=' })
    local parser = _G.assert(vim.treesitter.get_parser(buffer, 'lean'))

    assert.is_true(_G.assert(parser:parse())[1]:root():has_error())

    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { 'def value := 42' })

    assert.is_false(_G.assert(parser:parse())[1]:root():has_error())
  end)
end)
