local M = {}

---@param value string
---@return string
function M.trim(value) return vim.trim(value) end

---@param value string
---@return boolean
function M.is_blank(value) return M.trim(value) == '' end

return M
