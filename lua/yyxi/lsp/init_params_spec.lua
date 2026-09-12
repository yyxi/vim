local init_params = require('yyxi.lsp.init_params')

---@param root_uri any
---@return lsp.InitializeParams
local function params_with_root(root_uri)
  return {
    processId = vim.NIL,
    rootUri = root_uri,
    capabilities = {},
  }
end

describe('LSP initialize parameters', function()
  it(
    'returns nil for an omitted workspace root',
    function() assert.is_nil(init_params.root_path(params_with_root(nil))) end
  )

  it(
    'returns nil for Neovim protocol null',
    function() assert.is_nil(init_params.root_path(params_with_root(vim.NIL))) end
  )

  it(
    'converts a file URI to a path',
    function()
      assert.equals(
        '/tmp/a project',
        init_params.root_path(params_with_root('file:///tmp/a%20project'))
      )
    end
  )

  it('rejects an invalid workspace root type', function()
    assert.has_error(
      function() init_params.root_path(params_with_root({})) end,
      'LSP rootUri must be a string or null'
    )
  end)
end)
