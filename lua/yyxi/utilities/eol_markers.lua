local M = {}

local eol_markers_namespace = vim.api.nvim_create_namespace('eol_markers')
local configured = false

---@param bufnr integer
---@return boolean
local function is_enabled(bufnr) return vim.b[bufnr].yyxi_eol_markers_enabled == true end

local function configure_decoration_provider()
  vim.api.nvim_set_decoration_provider(eol_markers_namespace, {
    on_win = function(_, _, bufnr, topline, botline)
      if not is_enabled(bufnr) then return end

      local lines = vim.api.nvim_buf_get_lines(bufnr, topline, botline, false)
      for index, line in ipairs(lines) do
        if line ~= '' then
          vim.api.nvim_buf_set_extmark(bufnr, eol_markers_namespace, topline + index - 1, #line, {
            virt_text = { { '↳', 'NonText' } },
            virt_text_pos = 'overlay',
            hl_mode = 'combine',
            ephemeral = true,
          })
        end
      end
    end,
  })
end

function M.configure()
  if configured then return end
  configured = true
  configure_decoration_provider()
end

---@param bufnr? integer
function M.enable_for_buffer(bufnr)
  M.configure()
  vim.b[bufnr or 0].yyxi_eol_markers_enabled = true
end

---@param bufnr? integer
function M.disable_for_buffer(bufnr) vim.b[bufnr or 0].yyxi_eol_markers_enabled = false end

return M
