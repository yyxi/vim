local M = {}

local uv = vim.uv or vim.loop
local path_separator = package.config:sub(1, 1) == '\\' and ';' or ':'
local directory_separator = package.config:sub(1, 1)
local vendor_directory_name = 'vendor'
local lazy_directory_name = 'lazy'
local vendored_plugins_directory_name = 'plugins'
local plugin_manager_package_name = 'lazy.nvim'

---@param parts string[]
---@return string
function M.join_path(parts) return table.concat(parts, directory_separator) end

---@param path string
---@return boolean
function M.is_directory(path)
  local stat = uv.fs_stat(path)
  return stat ~= nil and stat.type == 'directory'
end

---@param path string
---@return boolean
function M.exists(path) return uv.fs_stat(path) ~= nil end

---@param path string
---@return boolean
function M.is_executable(path)
  if not M.exists(path) or M.is_directory(path) then return false end
  return vim.fn.executable(path) == 1
end

---@param value string?
---@return string[]
function M.path_entries(value)
  if not value or value == '' then return {} end
  return vim.split(value, path_separator, { trimempty = true })
end

---@param path_value string?
---@param directories string[]
---@return string
function M.prepend_path(path_value, directories)
  local entries = {}
  local seen = {}

  for _, directory in ipairs(directories) do
    if directory ~= '' and not seen[directory] then
      table.insert(entries, directory)
      seen[directory] = true
    end
  end

  for _, directory in ipairs(M.path_entries(path_value)) do
    if not seen[directory] then
      table.insert(entries, directory)
      seen[directory] = true
    end
  end

  return table.concat(entries, path_separator)
end

---@param directories string[]
---@return string[]
function M.existing_directories(directories)
  local existing = {}
  for _, directory in ipairs(directories) do
    if M.is_directory(directory) then table.insert(existing, directory) end
  end
  return existing
end

---@param name string
---@param path_value string?
---@return string?
function M.find_executable(name, path_value)
  if name:find(directory_separator, 1, true) and M.is_executable(name) then return name end

  for _, directory in ipairs(M.path_entries(path_value)) do
    local candidate = M.join_path({ directory, name })
    if M.is_executable(candidate) then return candidate end
  end

  return nil
end

---@param name string
---@param path_value string?
---@return boolean
function M.has_executable(name, path_value)
  return M.find_executable(name, path_value or vim.env.PATH) ~= nil
end

---@param path string
---@return string
function M.normalize_path(path)
  local expanded = vim.fn.expand(path)
  local resolved = vim.fn.resolve(expanded)
  return (vim.fs.normalize(resolved):gsub('/$', ''))
end

---@param path string
---@param directory string
---@return boolean
function M.is_path_within(path, directory)
  path = M.normalize_path(path)
  directory = M.normalize_path(directory)
  return path == directory or path:sub(1, #directory + 1) == directory .. '/'
end

---@param parts string[]
---@param root? string
---@return string
function M.repository_path(parts, root)
  local path_parts = { root or M.repository_root() }
  for _, part in ipairs(parts) do
    table.insert(path_parts, part)
  end
  return M.join_path(path_parts)
end

---@param root string
---@return string
function M.venv_bin(root) return M.repository_path({ '.venv', 'bin' }, root) end

---@param root string
---@return string
function M.node_bin(root) return M.repository_path({ 'node_modules', '.bin' }, root) end

---@param root? string
---@return string
function M.vendor_root(root) return M.repository_path({ vendor_directory_name }, root) end

---@param root? string
---@return string
function M.lazy_root(root)
  return M.repository_path({ vendor_directory_name, lazy_directory_name }, root)
end

---@param name string
---@param root? string
---@return string
function M.vendor_package_path(name, root)
  return M.repository_path({ vendor_directory_name, lazy_directory_name, name }, root)
end

---@param root? string
---@return string
function M.vendored_plugins_root(root)
  return M.repository_path({ vendor_directory_name, vendored_plugins_directory_name }, root)
end

---@param name string
---@param root? string
---@return string
function M.vendored_plugin_path(name, root)
  return M.repository_path({ vendor_directory_name, vendored_plugins_directory_name, name }, root)
end

---@param source_id string
---@param root? string
---@return string
function M.git_worktree_path(source_id, root)
  return M.repository_path({ vendor_directory_name, 'git', 'worktrees', source_id }, root)
end

---@param root? string
---@return string
function M.plugin_manager_path(root) return M.git_worktree_path(plugin_manager_package_name, root) end

---@param root? string
---@return string
function M.luarc_path(root) return M.repository_path({ '.luarc.json' }, root) end

---@param package_name string
---@param root string
---@return string?
function M.node_package_path(package_name, root)
  local parts = { 'node_modules' }
  for _, part in ipairs(vim.split(package_name, '/', { plain = true, trimempty = true })) do
    table.insert(parts, part)
  end

  local path = M.repository_path(parts, root)
  if M.is_directory(path) then return path end
  return nil
end

---@param root string
---@return string?
function M.python3_host_prog(root)
  -- Prefer the managed local host when present. If absent, leave provider
  -- discovery to Neovim by returning nil.
  local python = M.join_path({ M.venv_bin(root), 'python3' })
  if M.is_executable(python) then return python end
  return nil
end

---@param root string
---@return string?
function M.node_host_prog(root)
  -- Prefer the managed local Node host when present. If absent, leave
  -- provider discovery to Neovim by returning nil.
  local host = M.repository_path({ 'node_modules', 'neovim', 'bin', 'cli.js' }, root)
  if M.exists(host) and not M.is_directory(host) then return host end
  return nil
end

---@return string
function M.repository_root()
  local source = debug.getinfo(1, 'S').source
  local module_path = source:sub(1, 1) == '@' and source:sub(2) or source
  return vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(module_path))))
end

---@param path string
---@param root? string
---@param env? table<string,string>
---@return string?
function M.expand_luarc_library_path(path, root, env)
  if path:find('${3rd}', 1, true) then return path end

  local missing = false
  local expanded = path:gsub('%${env:([A-Za-z_][A-Za-z0-9_]*)}', function(name)
    env = env or vim.env
    if env[name] then return env[name] end
    missing = true
    return ''
  end)

  if missing or expanded:find('${', 1, true) then return nil end
  if not expanded:match('^/') then expanded = M.repository_path({ expanded }, root) end

  return M.normalize_path(expanded)
end

---@param root? string
---@return string[]
function M.luarc_workspace_libraries(root)
  root = root or M.repository_root()
  local config_path = M.luarc_path(root)
  if vim.fn.filereadable(config_path) ~= 1 then return {} end

  local ok, config = pcall(vim.json.decode, table.concat(vim.fn.readfile(config_path), '\n'))
  if not ok or type(config) ~= 'table' or type(config['workspace.library']) ~= 'table' then
    return {}
  end

  local libraries = {}
  for _, path in ipairs(config['workspace.library']) do
    if type(path) == 'string' then
      local expanded = M.expand_luarc_library_path(path, root)
      if expanded then table.insert(libraries, expanded) end
    end
  end

  return libraries
end

---@class yyxi.utilities.environment.ConfigureOptions
---@field root? string
---@field env? table<string,string>

---@class yyxi.utilities.environment.ConfigureResult
---@field root string
---@field path_directories string[]
---@field python3_host_prog string?
---@field node_host_prog string?

---@param opts? yyxi.utilities.environment.ConfigureOptions
---@return yyxi.utilities.environment.ConfigureResult
function M.configure(opts)
  opts = opts or {}
  local root = opts.root or M.repository_root()
  local env = opts.env or vim.env
  local path_directories = M.existing_directories({ M.venv_bin(root), M.node_bin(root) })

  env.PATH = M.prepend_path(env.PATH, path_directories)

  -- Only pin provider hosts when the managed local paths exist. Otherwise
  -- keep the globals unset so Neovim can use its built-in fallback logic.
  local python3_host_prog = M.python3_host_prog(root)
  if python3_host_prog then vim.g.python3_host_prog = python3_host_prog end

  local node_host_prog = M.node_host_prog(root)
  if node_host_prog then vim.g.node_host_prog = node_host_prog end

  return {
    root = root,
    path_directories = path_directories,
    python3_host_prog = python3_host_prog,
    node_host_prog = node_host_prog,
  }
end

M.path_separator = path_separator
M.directory_separator = directory_separator
M.vendor_directory_name = vendor_directory_name
M.lazy_directory_name = lazy_directory_name
M.vendored_plugins_directory_name = vendored_plugins_directory_name
M.plugin_manager_package_name = plugin_manager_package_name

return M
