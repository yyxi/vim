local assert = require('luassert')
local environment = require('yyxi.utilities.environment')

local function mkdir(path) vim.fn.mkdir(path, 'p') end

local function write_executable(path)
  vim.fn.writefile({ '#!/bin/sh', 'exit 0' }, path)
  vim.fn.setfperm(path, 'rwx------')
end

describe('yyxi.utilities.environment', function()
  it('prepends directories without duplicating existing entries', function()
    local sep = environment.path_separator
    local path = table.concat({ '/usr/bin', '/repo/.venv/bin' }, sep)

    local updated = environment.prepend_path(path, { '/repo/.venv/bin', '/repo/node_modules/.bin' })

    assert.equals(
      table.concat({ '/repo/.venv/bin', '/repo/node_modules/.bin', '/usr/bin' }, sep),
      updated
    )
  end)

  it('ignores missing local dependency directories when configuring PATH', function()
    local root = vim.fn.tempname()
    mkdir(root)
    local env = { PATH = '/usr/bin' }

    local configured = environment.configure({ root = root, env = env })

    assert.same({}, configured.path_directories)
    assert.equals('/usr/bin', env.PATH)
    vim.fn.delete(root, 'rf')
  end)

  it('discovers local Python and Node providers', function()
    local root = vim.fn.tempname()
    local venv_bin = environment.venv_bin(root)
    local node_host = environment.join_path({ root, 'node_modules', 'neovim', 'bin', 'cli.js' })
    mkdir(venv_bin)
    mkdir(vim.fs.dirname(node_host))
    write_executable(environment.join_path({ venv_bin, 'python3' }))
    vim.fn.writefile({ '#!/usr/bin/env node' }, node_host)

    assert.equals(
      environment.join_path({ venv_bin, 'python3' }),
      environment.python3_host_prog(root)
    )
    assert.equals(node_host, environment.node_host_prog(root))

    vim.fn.delete(root, 'rf')
  end)

  it('resolves scoped node package directories', function()
    local root = vim.fn.tempname()
    local package_path = environment.join_path({ root, 'node_modules', '@vue', 'language-server' })
    mkdir(package_path)

    assert.equals(package_path, environment.node_package_path('@vue/language-server', root))
    assert.is_nil(environment.node_package_path('@vue/missing', root))

    vim.fn.delete(root, 'rf')
  end)

  it('centralizes repository-local vendor paths', function()
    local root = '/repo'

    assert.equals('vendor', environment.vendor_directory_name)
    assert.equals('lazy.nvim', environment.plugin_manager_package_name)
    assert.equals(environment.join_path({ root, 'vendor' }), environment.vendor_root(root))
    assert.equals(
      environment.join_path({ root, 'vendor', 'lazy.nvim' }),
      environment.plugin_manager_path(root)
    )
    assert.equals(
      environment.join_path({ root, 'vendor', 'plenary.nvim' }),
      environment.vendor_package_path('plenary.nvim', root)
    )
  end)

  it('expands luarc workspace libraries from repository context', function()
    local root = vim.fn.tempname()
    mkdir(root)
    mkdir(environment.join_path({ root, 'vendor', 'plenary.nvim', 'lua' }))
    vim.fn.writefile({
      vim.json.encode({
        ['workspace.library'] = {
          '${3rd}/luv/library',
          'vendor/plenary.nvim/lua',
          '${env:HOME}/missing',
        },
      }),
    }, environment.luarc_path(root))

    assert.same({
      '${3rd}/luv/library',
      environment.join_path({ root, 'vendor', 'plenary.nvim', 'lua' }),
      environment.normalize_path(vim.fn.expand('~/missing')),
    }, environment.luarc_workspace_libraries(root))

    vim.fn.delete(root, 'rf')
  end)
end)
