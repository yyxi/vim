local log = require "vim.lsp.log"

local M = {
  fix_options = {},
  disabled = false,
  disabled_filetypes = {},
  saving_buffers = {},
  queue = {},
  buffers = {},
}

---@param bufnr number
local get_filetypes = function(bufnr)
  return vim.split(
    vim.api.nvim_get_option_value("filetype", { buf = bufnr }),
    ".",
    { plain = true, trimempty = true }
  )
end

---@param bufnr number
local filetype_fix_options = function(bufnr)
  local fix_options = {}
  for _, filetype in ipairs(get_filetypes(bufnr)) do
    if M.fix_options[filetype] then
      fix_options = vim.tbl_deep_extend("keep", fix_options,
        M.fix_options[filetype])
    end
  end
  return fix_options
end

---@param fix_options? table
M.setup = function(fix_options)
  M.fix_options = vim.tbl_deep_extend("force", M.fix_options,
    fix_options or {})
end

---@param key string
---@param value? string
---@return boolean|number|string|string[]
local parse_value = function(key, value)
  if not value then
    return true
  end
  if key == "order" or key == "exclude" then
    return vim.split(value, ",")
  end
  local int_value = tonumber(value)
  if int_value then
    return int_value
  end
  if value == "false" then
    return false
  end
  if value == "true" then
    return true
  end

  return value
end

M.fix = function()
  local bufnr = vim.api.nvim_get_current_buf()
  if M.saving_buffers[bufnr] or M.disabled then
    return
  end

  for _, filetype in ipairs(get_filetypes(bufnr)) do
    if M.disabled_filetypes[filetype] then
      return
    end
  end
  local fix_options = filetype_fix_options(bufnr)

  for key, option in pairs(fix_options) do
    if type(option) == "function" then
      fix_options[key] = option()
    end
  end

  -- for _, option in ipairs(options.fargs or {}) do
  --   local key, value = unpack(vim.split(option, "="))
  --   fix_options[key] = parse_value(key, value)
  -- end

  local get_clients = vim.lsp.get_clients
  if not get_clients then
    ---@diagnostic disable-next-line: deprecated
    get_clients = vim.lsp.get_active_clients
  end

  local clients = {}
  for _, client in ipairs(get_clients { bufnr = bufnr }) do
    if
        client
        and not vim.tbl_contains(fix_options.exclude or {}, client.name)
        and vim.tbl_contains(M.buffers[bufnr] or {}, client.id)
    then
      table.insert(clients, client)
    end
  end

  for _, client_name in pairs(fix_options.order or {}) do
    for i, client in pairs(clients) do
      if client.name == client_name then
        table.insert(clients, table.remove(clients, i))
        break
      end
    end
  end

  if #clients > 0 then
    table.insert(M.queue,
      { bufnr = bufnr, clients = clients, fix_options = fix_options })
    M._next()
  end
end

---@param client lsp.Client
---@param bufnr? number
M.on_attach = function(client, bufnr)
  if not bufnr then
    bufnr = vim.api.nvim_get_current_buf()
  end
  if M.buffers[bufnr] == nil then
    M.buffers[bufnr] = {}
  end
  table.insert(M.buffers[bufnr], client.id)
end

---@param bufnr number
---@param client lsp.Client
local fix = function(bufnr, client)
  if client.config and client.config.fix then
    for _, f in pairs(client.config.fix) do
      if type(f) == 'function' then
        f(bufnr, client)
      end
    end
  end

  M._next()
end

M._next = function()
  local next = M.queue[1]
  if not next or #next.clients == 0 then
    return
  end
  local next_client = table.remove(next.clients, 1)
  fix(next.bufnr, next_client)
  if #next.clients == 0 then
    table.remove(M.queue, 1)
  end
end

return M
