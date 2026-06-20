-- Async LSP format dispatch with deterministic per-filetype ordering.
--
-- Conform does not natively sort attached LSP clients: `lsp_format.format`
-- iterates whatever `vim.lsp.get_clients()` returns, which is by `client.id`
-- (i.e. startup-race order). For TOML buffers both tombi (Rust) and eslint
-- (Node) attach, and the order between them is unstable across sessions.
--
-- This module fires `conform.format` once per declared client, chained
-- asynchronously: each step kicks off only after the previous step's callback
-- has fired, so the second client sees the buffer state the first one
-- produced. Conform's existing safeguards (LspDetach autocmd, `changedtick`
-- discard, buffer validity) carry the failure modes; we simply advance the
-- chain on every callback regardless of err.

local M = {
  config = {},
}

local conform = require('conform')

---@class yyxi.lsp.format.FiletypeConfig
---@field order string[]  LSP client names, in declared format order.

---@class yyxi.lsp.format.Config
---@field [string] yyxi.lsp.format.FiletypeConfig

---Install per-filetype LSP format ordering. Lookup is **exact-match on
---`vim.bo[bufnr].filetype`** — compound filetypes (e.g. `yaml.ansible`) do
---NOT inherit from their base; declare them explicitly if needed. The same
---shape as `yyxi.lsp.fix.setup` so call sites in `yyxi.plugins.language_tools`
---read uniformly across the two dispatchers.
---@param config? yyxi.lsp.format.Config
function M.setup(config) M.config = vim.tbl_deep_extend('force', M.config, config or {}) end

---@param filetype string
---@return string[]|nil
local function order_for_filetype(filetype)
  local entry = M.config[filetype]
  if type(entry) == 'table' and type(entry.order) == 'table' then return entry.order end
  return nil
end

-- Buffers with a chain in flight. Suppresses re-entry from rapid `<leader>f`
-- presses: the second invocation would otherwise start a parallel chain that
-- conform's `changedtick` discard handles, but at the cost of doubled LSP
-- requests and unpredictable end state.
local in_flight = {}

---Run conform's CLI formatters from `formatters_by_ft` once, without
---touching any LSP. Fires once after the last LSP step so the ordered chain
---replicates conform's default LSP-then-CLI behavior. `quiet` suppresses
---the "no formatters available" notification when `formatters_by_ft[ft]`
---is empty (e.g. toml today).
---@param bufnr integer
---@param range conform.Range|nil
---@param on_done fun()
local function finalize_cli(bufnr, range, on_done)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    on_done()
    return
  end
  conform.format({
    async = true,
    bufnr = bufnr,
    lsp_format = 'never',
    quiet = true,
    range = range,
  }, function() on_done() end)
end

---@param bufnr integer
---@param order string[]
---@param range conform.Range|nil
---@param idx integer
local function step(bufnr, order, range, idx)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    in_flight[bufnr] = nil
    return
  end
  if idx > #order then
    finalize_cli(bufnr, range, function() in_flight[bufnr] = nil end)
    return
  end
  local name = order[idx]
  conform.format({
    async = true,
    bufnr = bufnr,
    lsp_format = 'prefer',
    -- An empty list disables conform's CLI-formatter pass *for this step*. CLI
    -- formatters from `formatters_by_ft` should run once at the end, via
    -- `finalize_cli`, not once per chain step.
    formatters = {},
    quiet = true,
    range = range,
    filter = function(client) return client.name == name end,
  }, function() step(bufnr, order, range, idx + 1) end)
end

---Entry point for the format keybind. For filetypes with a configured
---`order` (see `M.setup`), runs an async chain of conform.format calls in
---the declared order; for all others, delegates to a single conform.format
---call with the existing `lsp_format = 'first'` policy.
---@param range conform.Range|nil  Range to format; nil = full buffer.
function M.run(range)
  local bufnr = vim.api.nvim_get_current_buf()
  local order = order_for_filetype(vim.bo[bufnr].filetype)
  if order == nil then
    conform.format({
      async = true,
      bufnr = bufnr,
      lsp_format = 'first',
      range = range,
    })
    return
  end
  if in_flight[bufnr] then return end
  in_flight[bufnr] = true
  step(bufnr, order, range, 1)
end

-- Internal: spec only.
M._reset_for_tests = function()
  in_flight = {}
  M.config = {}
end

return M
