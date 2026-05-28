local M = {}

---@param values string[]
---@return string[]
local function unique(values)
  local result = {}
  local seen = {}

  for _, value in ipairs(values) do
    if value ~= '' and not seen[value] then
      table.insert(result, value)
      seen[value] = true
    end
  end

  return result
end

---@param path string
---@param pattern string
---@return boolean
local function matches_pattern(path, pattern)
  local regex = vim.fn.glob2regpat(pattern)
  local basename = vim.fs.basename(path)
  return vim.fn.match(path, regex) ~= -1 or vim.fn.match(basename, regex) ~= -1
end

---@param patterns string[]
---@return string[]
function M.backupskip_patterns(patterns) return unique(patterns) end

---@param path string
---@param patterns string[]
---@return boolean
function M.matches_path(path, patterns)
  if path == '' then return false end

  for _, pattern in ipairs(patterns) do
    if matches_pattern(path, pattern) then return true end
  end

  return false
end

---@param bufnr integer
function M.harden_buffer(bufnr)
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].undofile = false
end

---@param patterns string[]
function M.setup(patterns)
  patterns = M.backupskip_patterns(patterns)
  vim.opt.backupskip:append(patterns)

  local group = vim.api.nvim_create_augroup('SensitiveFiles', { clear = true })

  vim.api.nvim_create_autocmd({ 'BufReadPre', 'BufNewFile' }, {
    group = group,
    pattern = '*',
    callback = function(args)
      local path = vim.api.nvim_buf_get_name(args.buf)
      if M.matches_path(path, patterns) then M.harden_buffer(args.buf) end
    end,
  })
end

return M
