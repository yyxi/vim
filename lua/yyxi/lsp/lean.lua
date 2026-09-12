local environment = require('yyxi.utilities.environment')

local M = {}

-- Root selection and launch behavior are adapted from lean.nvim at
-- 5a2c1dff42ca1055dc8977f1ad3217e42ce72659.
-- Copyright (c) 2020 Julian Berman, used under the MIT license:
-- https://github.com/Julian/lean.nvim/blob/5a2c1dff42ca1055dc8977f1ad3217e42ce72659/COPYING

local ROOT_MARKERS = { 'lakefile.toml', 'lakefile.lean', 'lean-toolchain' }

local function is_file(path)
  local stat = vim.uv.fs_stat(path)
  return stat ~= nil and stat.type == 'file'
end

local function is_core_lean_directory(directory)
  local function contains(paths)
    return vim
      .iter(paths)
      :all(function(path) return vim.uv.fs_stat(vim.fs.joinpath(directory, path)) ~= nil end)
  end

  return contains({ 'Init.lean', 'Lean.lean', 'kernel', 'runtime' })
    or contains({ 'LICENSE', 'LICENSES', 'src' })
end

local function containing_path(path, marker)
  local start, finish = (path .. '/'):find(marker, 1, true)
  if not start then return nil end
  return path:sub(1, finish - 1)
end

---@param path string
---@return string
function M.root_for_path(path)
  local normalized = vim.fs.normalize(path)
  local packages_start = (normalized .. '/'):find('/.lake/packages/', 1, true)
  if packages_start then return normalized:sub(1, packages_start - 1) end

  local project_root = vim.fs.root(normalized, ROOT_MARKERS)
  if project_root then return project_root end

  for parent in vim.fs.parents(normalized) do
    if is_core_lean_directory(parent) then return parent end
  end

  local stdlib_root = containing_path(normalized, '/src/lean/')
    or containing_path(normalized, '/lib/lean/')
  if stdlib_root then return stdlib_root end

  local git_root = vim.fs.root(normalized, '.git')
  if git_root then return git_root end

  local stat = vim.uv.fs_stat(normalized)
  return stat and stat.type == 'directory' and normalized or vim.fs.dirname(normalized)
end

---@param bufnr integer
---@param on_dir fun(root_dir?: string)
function M.root_dir(bufnr, on_dir)
  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == '' then
    on_dir(nil)
    return
  end
  on_dir(M.root_for_path(path))
end

local function read_first_line(path)
  local file = io.open(path, 'r')
  if not file then return nil end
  local line = file:read('*l')
  file:close()
  if not line then return nil end
  line = vim.trim(line)
  return line ~= '' and line or nil
end

local function elan_home(env)
  if env.ELAN_HOME and env.ELAN_HOME ~= '' then return vim.fs.normalize(env.ELAN_HOME) end
  if env.HOME and env.HOME ~= '' then return vim.fs.joinpath(env.HOME, '.elan') end
  return nil
end

local function default_toolchain(home)
  local settings = read_first_line(vim.fs.joinpath(home, 'settings.toml'))
  if settings and settings:match('^default_toolchain%s*=') then
    return settings:match('^default_toolchain%s*=%s*["\']([^"\']+)["\']')
  end

  local file = io.open(vim.fs.joinpath(home, 'settings.toml'), 'r')
  if not file then return nil end
  local content = file:read('*a')
  file:close()
  return content:match('[\r\n]default_toolchain%s*=%s*["\']([^"\']+)["\']')
end

local function toolchain_directory_name(name)
  if not name:match('^[A-Za-z0-9._+:/-]+$') then return nil end
  return (name:gsub('/', '--'):gsub(':', '---'))
end

local function enclosing_installed_toolchain(root, home)
  local toolchains = vim.fs.joinpath(home, 'toolchains')
  local relative = vim.fs.relpath(toolchains, root)
  if not relative or relative == '.' then return nil end
  local directory = relative:match('^([^/]+)')
  return directory and vim.fs.joinpath(toolchains, directory) or nil
end

local function requested_toolchain(root, home, env)
  if env.ELAN_TOOLCHAIN and env.ELAN_TOOLCHAIN ~= '' then return env.ELAN_TOOLCHAIN end
  return read_first_line(vim.fs.joinpath(root, 'lean-toolchain')) or default_toolchain(home)
end

local function uses_lake(root)
  if is_core_lean_directory(root) then return false end
  return is_file(vim.fs.joinpath(root, 'lakefile.lean'))
    or is_file(vim.fs.joinpath(root, 'lakefile.toml'))
end

---@class yyxi.lsp.lean.Launch
---@field command string[]
---@field cwd string
---@field env table<string,string>

---@param root string
---@param env? table<string,string>
---@return yyxi.lsp.lean.Launch? launch
---@return string? failure
function M.launch(root, env)
  env = env or vim.fn.environ()
  local program = uses_lake(root) and 'lake' or 'lean'
  local home = elan_home(env)
  local toolchain_root
  local toolchain_name

  if home then
    toolchain_root = enclosing_installed_toolchain(root, home)
    if not toolchain_root then
      toolchain_name = requested_toolchain(root, home, env)
      if toolchain_name then
        local directory = toolchain_directory_name(toolchain_name)
        if not directory then
          return nil, ('invalid Lean toolchain name: %s'):format(toolchain_name)
        end
        toolchain_root = vim.fs.joinpath(home, 'toolchains', directory)
      end
    end
  end

  local executable
  local bin
  if toolchain_root then
    bin = vim.fs.joinpath(toolchain_root, 'bin')
    executable = vim.fs.joinpath(bin, program)
    if not environment.is_executable(executable) then
      local identity = toolchain_name or vim.fs.basename(toolchain_root)
      return nil,
        ('Lean toolchain %s is not installed at %s; install it explicitly before opening Lean files'):format(
          identity,
          toolchain_root
        )
    end
  else
    executable = environment.find_executable(program, env.PATH)
    if not executable then
      return nil,
        ('%s is not installed; install Lean explicitly before opening Lean files'):format(program)
    end
    bin = vim.fs.dirname(executable)
    if environment.is_executable(vim.fs.joinpath(bin, 'elan')) then
      return nil,
        ('refusing to invoke the Elan %s proxy without a resolved installed toolchain'):format(
          program
        )
    end
  end

  local command = uses_lake(root) and { executable, 'serve', '--', root }
    or { executable, '--server', root }
  local command_env = vim.tbl_extend('force', {}, env)
  command_env.PATH = environment.prepend_path(command_env.PATH, { bin })

  return { command = command, cwd = root, env = command_env }, nil
end

local function start(dispatchers, config)
  if not config.root_dir then error('leanls requires a project or file root', 0) end
  local launch, failure = M.launch(config.root_dir)
  if not launch then error(failure, 0) end

  local command_env = vim.tbl_extend('force', launch.env, config.cmd_env or {})
  command_env.PATH = environment.prepend_path(command_env.PATH, {
    vim.fs.dirname(launch.command[1]),
  })

  return vim.lsp.rpc.start(launch.command, dispatchers, {
    cwd = launch.cwd,
    env = command_env,
    detached = config.detached,
  })
end

local function add_dependency_build_mode(client)
  local original_notify = client.notify
  client.notify = function(self, method, params)
    if method == 'textDocument/didOpen' and type(params) == 'table' then
      params.dependencyBuildMode = params.dependencyBuildMode or 'never'
    end
    return original_notify(self, method, params)
  end
end

---@return vim.lsp.Config
function M.config()
  return {
    cmd = start,
    filetypes = { 'lean' },
    root_dir = M.root_dir,
    init_options = { hasWidgets = false },
    handlers = {
      -- Lean emits processing progress even when no UI consumes it. Ignore that
      -- optional signal deliberately rather than installing Lean-specific signs.
      ['$/lean/fileProgress'] = function() end,
    },
    on_init = add_dependency_build_mode,
  }
end

return M
