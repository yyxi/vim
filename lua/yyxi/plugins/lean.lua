local M = {}

-- Buffer defaults and matchit expressions are adapted from lean.nvim at
-- 5a2c1dff42ca1055dc8977f1ad3217e42ce72659.
-- Copyright (c) 2020 Julian Berman, used under the MIT license:
-- https://github.com/Julian/lean.nvim/blob/5a2c1dff42ca1055dc8977f1ad3217e42ce72659/COPYING

local SKIPPED_NODE_TYPES = {
  block_comment = true,
  char_lit = true,
  doc_comment = true,
  interpolated_str = true,
  line_comment = true,
  module_doc_comment = true,
  name_lit = true,
  raw_string = true,
  str_lit = true,
}

---@param bufnr? integer
---@param row? integer zero-based row; defaults to the cursor row
---@param column? integer zero-based byte column; defaults to the cursor column
---@return boolean
function M.matchup_skip(bufnr, row, column)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if row == nil or column == nil then
    local cursor = vim.api.nvim_win_get_cursor(0)
    row = row or cursor[1] - 1
    column = column or cursor[2]
  end

  local parser_ok, parser = pcall(vim.treesitter.get_parser, bufnr, 'lean')
  if not parser_ok or not parser then return false end
  local parse_ok = pcall(parser.parse, parser)
  if not parse_ok then return false end

  local ok, node = pcall(vim.treesitter.get_node, {
    bufnr = bufnr,
    lang = 'lean',
    pos = { row, column },
  })
  if not ok then return false end

  while node do
    -- An interpolation is Lean code inside an interpolated string, so matchup
    -- keywords in it remain active even though its parent is string content.
    if node:type() == 'interpolation' then return false end
    if SKIPPED_NODE_TYPES[node:type()] then return true end
    node = node:parent()
  end

  return false
end

local function append_undo(command)
  local existing = vim.b.undo_ftplugin
  vim.b.undo_ftplugin = existing and existing .. ' | ' .. command or command
end

function M.configure_buffer()
  vim.opt_local.iskeyword = [[a-z,A-Z,_,48-57,192-255,!,',?,#]]
  vim.opt_local.comments = [[s0:/-,mb: ,ex:-/,:--]]
  vim.opt_local.commentstring = [[-- %s]]
  vim.opt_local.includeexpr = [[substitute(v:fname, '\.', '/', 'g') . '.lean']]
  vim.opt_local.expandtab = true
  vim.opt_local.shiftwidth = 2
  vim.opt_local.softtabstop = 2

  for _, pair in ipairs({ '⟨:⟩', '‹:›', '«:»' }) do
    vim.opt_local.matchpairs:append(pair)
  end

  vim.b.match_ignorecase = 0
  vim.b.match_words = table.concat({
    [[\<\%(namespace\|section\)\s\+\([^«»]\{-}\>\|«.\{-}»\):\<end\s\+\1]],
    [[^\s*section\s*$:^end\s*$]],
    [[\<if\>:\<then\>:\<else\>]],
    [[\/\-[-\s]\?:-\/]],
  }, ',')
  -- Matchup evaluates this expression while its search cursor moves. Its
  -- effective position helpers let the Tree-sitter check inspect each match.
  vim.b.match_skip = table.concat({
    "v:lua.require'yyxi.plugins.lean'.matchup_skip(",
    "bufnr('%'),s:effline('.')-1,s:effcol('.')-1)",
  })

  append_undo(
    'setlocal comments< commentstring< expandtab< includeexpr< iskeyword< matchpairs< shiftwidth< softtabstop<'
      .. ' | unlet! b:match_ignorecase b:match_skip b:match_words'
  )
end

return M
