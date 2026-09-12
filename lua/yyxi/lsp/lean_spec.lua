local assert = require('luassert')
local lean = require('yyxi.lsp.lean')

local function mkdir(path) vim.fn.mkdir(path, 'p') end

local function touch(path, lines)
  mkdir(vim.fs.dirname(path))
  vim.fn.writefile(lines or {}, path)
end

local function executable(path)
  touch(path, { '#!/bin/sh', 'exit 0' })
  vim.fn.setfperm(path, 'rwx------')
end

describe('yyxi.lsp.lean', function()
  local root

  before_each(function()
    root = vim.fn.tempname()
    mkdir(root)
  end)

  after_each(function() vim.fn.delete(root, 'rf') end)

  it('selects Lake, package, standalone, and standard-library roots', function()
    local project = vim.fs.joinpath(root, 'project')
    touch(vim.fs.joinpath(project, 'lakefile.toml'))
    local source = vim.fs.joinpath(project, 'Example.lean')
    touch(source)

    assert.equals(project, lean.root_for_path(source))
    assert.equals(
      project,
      lean.root_for_path(vim.fs.joinpath(project, '.lake', 'packages', 'dep', 'Dep.lean'))
    )

    local standalone = vim.fs.joinpath(root, 'standalone', 'Example.lean')
    touch(standalone)
    assert.equals(vim.fs.dirname(standalone), lean.root_for_path(standalone))

    local stdlib = vim.fs.joinpath(root, 'toolchain', 'lib', 'lean', 'Init', 'Prelude.lean')
    touch(stdlib)
    assert.equals(vim.fs.joinpath(root, 'toolchain', 'lib', 'lean'), lean.root_for_path(stdlib))
  end)

  it('launches Lake directly from an already-installed project toolchain', function()
    local home = vim.fs.joinpath(root, 'home')
    local project = vim.fs.joinpath(root, 'project')
    local toolchain = vim.fs.joinpath(home, '.elan', 'toolchains', 'leanprover--lean4---v4.28.0')
    local lake = vim.fs.joinpath(toolchain, 'bin', 'lake')
    executable(lake)
    touch(vim.fs.joinpath(project, 'lakefile.toml'))
    touch(vim.fs.joinpath(project, 'lean-toolchain'), { 'leanprover/lean4:v4.28.0' })

    local launch = _G.assert(lean.launch(project, { HOME = home, PATH = '/usr/bin' }))

    assert.same({ lake, 'serve', '--', project }, launch.command)
    assert.equals(project, launch.cwd)
    assert.equals(vim.fs.dirname(lake) .. ':/usr/bin', launch.env.PATH)
  end)

  it('uses the enclosing installed toolchain for its own source files', function()
    local home = vim.fs.joinpath(root, 'home')
    local toolchain = vim.fs.joinpath(home, '.elan', 'toolchains', 'local-toolchain')
    local lean_executable = vim.fs.joinpath(toolchain, 'bin', 'lean')
    local stdlib = vim.fs.joinpath(toolchain, 'src', 'lean')
    executable(lean_executable)
    mkdir(stdlib)

    local launch = _G.assert(lean.launch(stdlib, { HOME = home, PATH = '/usr/bin' }))

    assert.same({ lean_executable, '--server', stdlib }, launch.command)
  end)

  it('fails safely instead of invoking an unavailable Elan toolchain', function()
    local home = vim.fs.joinpath(root, 'home')
    local project = vim.fs.joinpath(root, 'project')
    touch(vim.fs.joinpath(project, 'lean-toolchain'), { 'leanprover/lean4:v99.0.0' })

    local launch, failure = lean.launch(project, { HOME = home, PATH = '/usr/bin' })

    assert.is_nil(launch)
    assert.matches('is not installed', failure)
    assert.matches('install it explicitly', failure)
  end)

  it('never falls back to an Elan proxy that could acquire a toolchain', function()
    local home = vim.fs.joinpath(root, 'home')
    local bin = vim.fs.joinpath(root, 'bin')
    executable(vim.fs.joinpath(bin, 'lean'))
    executable(vim.fs.joinpath(bin, 'elan'))

    local launch, failure = lean.launch(root, { HOME = home, PATH = bin })

    assert.is_nil(launch)
    assert.matches('refusing to invoke the Elan lean proxy', failure)
  end)

  it('requests no widgets or Lean UI and prevents dependency builds on open', function()
    local config = lean.config()
    local sent
    local client = {
      notify = function(_, method, params) sent = { method = method, params = params } end,
    }

    config.on_init(client, { capabilities = {} })
    client:notify('textDocument/didOpen', { textDocument = { uri = 'file:///Example.lean' } })

    assert.same({ hasWidgets = false }, config.init_options)
    assert.is_nil(config.capabilities)
    assert.is_function(config.handlers['$/lean/fileProgress'])
    assert.equals('textDocument/didOpen', sent.method)
    assert.equals('never', sent.params.dependencyBuildMode)
  end)
end)
