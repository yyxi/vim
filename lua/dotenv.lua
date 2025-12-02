---@diagnostic disable: missing-parameter
-- main module file
local uv = vim.loop

dotenv = {}

local function read_file(path)
  local fd = assert(uv.fs_open(path, 'r', 438))
  local stat = assert(uv.fs_fstat(fd))
  local data = assert(uv.fs_read(fd, stat.size, 0))
  assert(uv.fs_close(fd))
  return data
end

local function parse_data(data)
  local values = vim.split(data, '\n')
  local out = {}
  for _, pair in pairs(values) do
    pair = vim.trim(pair)
    if not vim.startswith(pair, '#') and pair ~= '' then
      local splitted = vim.split(pair, '=')
      if #splitted > 1 then
        local key = splitted[1]
        local v = {}
        for i = 2, #splitted, 1 do
          local k = vim.trim(splitted[i])
          if k ~= '' then
            table.insert(v, splitted[i])
          end
        end
        if #v > 0 then
          local value = table.concat(v, '=')
          value, _ = string.gsub(value, '"', '')
          vim.env[key] = value
          out[key] = value
        end
      end
    end
  end
  return out
end

-- safe loader: does NOT error if file is missing
local function load(file)
  local ok, data = pcall(read_file, file)
  if not ok or not data then
    return {}
  end
  return parse_data(data)
end

-- read ~/.vim/.env and ~/.vim/.env.local (if they exist)
do
  local home = vim.fn.expand('~')
  local env_files = {
    home .. '/.vim/.env',
    home .. '/.vim/.env.local',
  }

  for _, file in ipairs(env_files) do
    local vars = load(file)
    for k, v in pairs(vars) do
      -- later files (e.g. .env.local) override earlier ones
      dotenv[k] = v
    end
  end
end

return dotenv
