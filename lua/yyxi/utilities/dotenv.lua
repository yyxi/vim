local uv = vim.uv or vim.loop

local M = {
  values = {},
}

---@alias yyxi.utilities.dotenv.Environment table<string, string>

---@param path string
---@return string
local function read_file(path)
  local fd = assert(uv.fs_open(path, 'r', 438))
  local stat = assert(uv.fs_fstat(fd))
  local data = assert(uv.fs_read(fd, stat.size, 0))
  assert(uv.fs_close(fd))
  return data
end

---@param value string
---@return string
local function unquote(value)
  local unquoted = value:gsub('"', '')
  return unquoted
end

---@param pair string
---@param env yyxi.utilities.dotenv.Environment
---@return string? key
---@return string? value
local function parse_pair(pair, env)
  local trimmed = vim.trim(pair)
  if trimmed == '' or vim.startswith(trimmed, '#') then return nil, nil end

  local parts = vim.split(trimmed, '=')
  if #parts <= 1 then return nil, nil end

  local key = vim.trim(parts[1])
  if key == '' then return nil, nil end

  local values = {}
  for index = 2, #parts do
    local value = parts[index]
    if vim.trim(value) ~= '' then table.insert(values, value) end
  end

  if #values == 0 then return nil, nil end

  local value = unquote(table.concat(values, '='))
  env[key] = value
  return key, value
end

---@param data string
---@param env? yyxi.utilities.dotenv.Environment
---@return table<string, string>
function M.parse(data, env)
  env = env or vim.env

  local parsed = {}
  for _, pair in ipairs(vim.split(data, '\n')) do
    local key, value = parse_pair(pair, env)
    if key and value then parsed[key] = value end
  end

  return parsed
end

---@param file string
---@param env? yyxi.utilities.dotenv.Environment
---@return table<string, string>
function M.load(file, env)
  local ok, data = pcall(read_file, file)
  if not ok or not data then return {} end
  return M.parse(data, env)
end

---@param files string[]
---@param env? yyxi.utilities.dotenv.Environment
---@return table<string, string>
function M.load_files(files, env)
  local loaded = {}

  for _, file in ipairs(files) do
    local values = M.load(file, env)
    for key, value in pairs(values) do
      loaded[key] = value
    end
  end

  return loaded
end

---@param home? string
---@param env? yyxi.utilities.dotenv.Environment
---@return table<string, string>
function M.load_defaults(home, env)
  home = home or vim.fn.expand('~')
  local files = {
    home .. '/.vim/.env',
    home .. '/.vim/.env.local',
  }

  return M.load_files(files, env)
end

M.values = M.load_defaults()

return M
