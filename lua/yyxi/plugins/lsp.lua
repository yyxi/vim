local M = {}

---@class yyxi.plugins.lsp.Context
---@field concat fun(first: table, second: table): table
---@field is_installed fun(binary: string): boolean
---@field ternary fun(condition: any, true_value: any, false_value?: any): any

---@param context yyxi.plugins.lsp.Context
function M.setup(context)
  local concat = context.concat
  local is_installed = context.is_installed
  local ternary = context.ternary

  vim.lsp.set_log_level('ERROR')
  local mason = require('mason-registry')

  require('lspconfig.ui.windows').default_options.border = 'rounded'

  local capabilities = vim.tbl_deep_extend(
    'force',
    vim.lsp.protocol.make_client_capabilities(),
    require('blink.cmp').get_lsp_capabilities({}, false)
  )

  local function unanimous_var_for_root(root_path, varname)
    local candidate ---@type any|nil

    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(bufnr) then
        local path = vim.api.nvim_buf_get_name(bufnr)
        if path:sub(1, #root_path) == root_path then
          local val = vim.b[bufnr][varname]
          if val then -- ignore nils
            if candidate and candidate ~= val then
              return nil -- mismatch → not unanimous
            end
            candidate = candidate or val -- remember first non-nil value
          end
        end
      end
    end

    return candidate -- may be nil
  end

  local on_attach = function(client, bufnr)
    vim.api.nvim_buf_set_keymap(
      bufnr,
      'n',
      '<C-k>',
      '<cmd>lua vim.lsp.buf.signature_help({ border = "rounded" })<cr>',
      { noremap = true, silent = true, desc = 'Signature Help' }
    )
    vim.api.nvim_buf_set_keymap(
      bufnr,
      'n',
      'K',
      "<cmd>lua vim.lsp.buf.hover({ border = 'rounded', focus = false, focusable = true, close_events = { 'LspDetach', 'BufHidden', 'CursorMoved' } })<cr>",
      { noremap = true, silent = true, desc = 'Hover' }
    )
    vim.api.nvim_buf_set_keymap(
      bufnr,
      'n',
      '<leader>r',
      '<cmd>lua vim.lsp.buf.rename()<cr>',
      { noremap = true, silent = true, desc = 'Rename' }
    )

    vim.api.nvim_buf_set_keymap(
      bufnr,
      'n',
      '<leader>A',
      '<cmd>lua vim.lsp.buf.code_action()<cr>',
      { noremap = true, silent = true, desc = 'Code Action' }
    )

    vim.api.nvim_buf_set_keymap(
      bufnr,
      'x',
      '<leader>A',
      '<cmd>lua vim.lsp.buf.code_action()<cr>',
      { noremap = true, silent = true, desc = 'Code Action' }
    )

    vim.api.nvim_buf_set_keymap(
      bufnr,
      'n',
      '<C-Up>',
      "<cmd>lua vim.diagnostic.jump({ count = -1, float = true, focus = false, focusable = false, scope = 'cursor', close_events = { 'BufLeave', 'CursorMoved', 'InsertEnter' } })<cr>",
      { noremap = true, silent = true, desc = 'Previous Diagnostic' }
    )

    vim.api.nvim_buf_set_keymap(
      bufnr,
      'n',
      '<C-Down>',
      "<cmd>lua vim.diagnostic.jump({ count = 1, float = true, focus = false, focusable = false, scope = 'cursor', close_events = { 'BufLeave', 'CursorMoved', 'InsertEnter' } })<cr>",
      { noremap = true, silent = true, desc = 'Next Diagnostic' }
    )

    require('lsp-fix').on_attach(client, bufnr)

    if client.name == 'ruff' then client.server_capabilities.hoverProvider = false end

    if client.name == 'cssls' then client.server_capabilities.diagnosticProvider = false end
  end

  vim.api.nvim_create_autocmd('LspAttach', {
    desc = 'LSP actions',
    callback = function(event)
      local client = vim.lsp.get_client_by_id(event.data.client_id)
      if not client then return end

      local bufnr = event.buf
      on_attach(client, bufnr)
    end,
  })

  local handlers = {
    harper_ls = ternary(is_installed('harper-ls'), function()
      vim.lsp.config('harper_ls', {
        capabilities = capabilities,
        filetypes = {
          'gitcommit',
          'markdown',
          'text',
        },
        settings = {
          ['harper-ls'] = {
            userDictPath = '',
            fileDictPath = '',
            linters = {
              EllipsisLength = false,
              LongSentences = false,
              PhrasalVerbAsCompoundNoun = false,
              SentenceCapitalization = false,
              SpellCheck = false,
              SpelledNumbers = false,
              WrongQuotes = false,
              UseTitleCase = false,
            },
            codeActions = {
              ForceStable = false,
            },
            markdown = {
              IgnoreLinkTitle = false,
            },
            diagnosticSeverity = 'hint',
            isolateEnglish = false,
            dialect = 'American',
            maxFileLength = 120000,
          },
        },
      })

      return true
    end),
    ansiblels = ternary(is_installed('ansible-config'), function()
      vim.lsp.config('ansiblels', {
        capabilities = capabilities,
        settings = {
          ansible = {
            python = {
              interpreterPath = 'python',
            },
            ansible = {
              path = 'ansible',
            },
            executionEnvironment = {
              enabled = false,
            },
            validation = {
              enabled = true,
              lint = {
                enabled = is_installed('ansible-lint'),
                path = 'ansible-lint',
              },
            },
          },
        },
      })

      return true
    end),
    yamlls = function()
      vim.lsp.config('yamlls', {
        capabilities = capabilities,
        settings = {
          yaml = {
            schemas = vim.list_extend({
              ['https://json.schemastore.org/lefthook.json'] = {
                '/{.lefthook,lefthook,lefthook-local,.lefthook-local}.{yml,yaml,toml,json}',
              },
            }, require('schemastore').yaml.schemas()),
            validate = { enable = true },
          },
        },
        before_init = function(params, config)
          if params.rootUri then
            local root_path = vim.uri_to_fname(params.rootUri)
            local quotePreference = unanimous_var_for_root(root_path, 'quote_type') or 'auto'

            if quotePreference ~= 'auto' then
              config.settings.yaml.format.singleQuote = quotePreference == 'single'
            end
          end
        end,
      })

      return true
    end,
    jsonls = function()
      vim.lsp.config('jsonls', {
        capabilities = capabilities,
        settings = {
          json = {
            schemas = require('schemastore').json.schemas(),
            validate = { enable = true },
          },
        },
      })

      return true
    end,
    -- lua_ls = function()
    --   require('lazydev').setup({
    --     library = {
    --       -- See the configuration section for more details
    --       -- Load luvit types when the `vim.uv` word is found
    --       { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
    --     },
    --   })
    -- end,
    ty = function()
      vim.lsp.config('ty', {
        capabilities = capabilities,
        -- fix = {
        --   function(bufnr, client)
        --     client.request_sync('workspace/executeCommand', {
        --       command = 'pyright.organizeimports',
        --       arguments = { vim.uri_from_bufnr(bufnr) },
        --     }, 3000, bufnr)
        --   end,
        -- },
      })

      return true
    end,
    pyright = function()
      vim.lsp.config('pyright', {
        capabilities = capabilities,
        fix = {
          function(bufnr, client)
            client.request_sync('workspace/executeCommand', {
              command = 'pyright.organizeimports',
              arguments = { vim.uri_from_bufnr(bufnr) },
            }, 3000, bufnr)
          end,
        },
      })

      return true
    end,
    ruff = function()
      vim.lsp.config('ruff', {
        capabilities = capabilities,
        fix = {
          function(bufnr, client)
            client.request_sync('workspace/executeCommand', {
              command = 'ruff.applyOrganizeImports',
              arguments = {
                {
                  uri = vim.uri_from_bufnr(bufnr),
                  version = vim.lsp.util.buf_versions[bufnr],
                },
              },
            }, 3000, bufnr)
          end,
          function(bufnr, client)
            client.request_sync('workspace/executeCommand', {
              command = 'ruff.applyAutofix',
              arguments = {
                {
                  uri = vim.uri_from_bufnr(bufnr),
                  version = vim.lsp.util.buf_versions[bufnr],
                },
              },
            }, 3000, bufnr)
          end,
        },
      })

      return true
    end,
    vtsls = ternary(is_installed('vtsls'), function()
      local hasVolar = mason.is_installed('vue-language-server')

      -- https://github.com/yioneko/vtsls/blob/main/packages/service/configuration.schema.json
      local tsWorkspaceConfiguration = {
        inlayHints = {
          parameterNames = { enabled = 'literals' },
          parameterTypes = { enabled = true },
          variableTypes = { enabled = true },
          propertyDeclarationTypes = { enabled = true },
          functionLikeReturnTypes = { enabled = true },
          enumMemberValues = { enabled = true },
        },
        format = {
          indentSize = vim.opt_local.shiftwidth:get(),
          convertTabsToSpaces = vim.opt_local.expandtab:get(),
          tabSize = vim.opt_local.tabstop:get(),
          indentStyle = 2, -- 'Smart',
          semicolons = 'remove',
          trimTrailingWhitespace = false,
          insertSpaceAfterCommaDelimiter = true,
          placeOpenBraceOnNewLineForControlBlocks = false,
          placeOpenBraceOnNewLineForFunctions = false,
          insertSpaceAfterConstructor = false,
          insertSpaceAfterFunctionKeywordForAnonymousFunctions = true,
          insertSpaceAfterKeywordsInControlFlowStatements = true,
          insertSpaceAfterOpeningAndBeforeClosingEmptyBraces = false,
          insertSpaceAfterOpeningAndBeforeClosingJsxExpressionBraces = false,
          insertSpaceAfterOpeningAndBeforeClosingNonemptyBraces = true,
          insertSpaceAfterOpeningAndBeforeClosingNonemptyBrackets = false,
          insertSpaceAfterOpeningAndBeforeClosingNonemptyParenthesis = false,
          insertSpaceAfterOpeningAndBeforeClosingTemplateStringBraces = false,
          insertSpaceAfterSemicolonInForStatements = true,
          insertSpaceAfterTypeAssertion = false,
          insertSpaceBeforeAndAfterBinaryOperators = true,
          insertSpaceBeforeFunctionParenthesis = false,
          insertSpaceBeforeTypeAnnotation = false,
        },
        preferences = {
          -- Supported values 'auto', 'double', 'single'
          quoteStyle = 'auto',
          importModuleSpecifier = 'relative',
          importModuleSpecifierEnding = 'minimal',
          organizeImports = {
            caseSensitivity = 'caseSensitive',
            typeOrder = 'last',
            unicodeCollation = 'unicode',
            locale = 'en-US',
            accentCollation = 'false',
            numericCollation = 'true',
            caseFirst = 'upper',
          },
        },
        suggest = {
          completeJSDocs = false,
          jsdoc = {
            generateReturns = false,
          },
        },
        check = { npmIsInstalled = false },
        disableAutomaticTypeAcquisition = true,
        updateImportsOnFileMove = 'always',
      }

      vim.lsp.config('vtsls', {
        capabilities = capabilities,
        fix = {
          function(bufnr, client)
            client.request_sync('workspace/executeCommand', {
              command = 'typescript.organizeImports',
              arguments = { vim.api.nvim_buf_get_name(bufnr) },
            }, 3000, bufnr)

            client.request_sync('workspace/executeCommand', {
              command = 'typescript.sortImportsImports',
              arguments = { vim.api.nvim_buf_get_name(bufnr) },
            }, 3000, bufnr)
          end,
        },
        filetypes = concat({
          'typescript',
          'javascript',
          'javascriptreact',
          'typescriptreact',
        }, hasVolar and { 'vue' } or {}),
        -- init_options = {},
        settings = {
          typescript = tsWorkspaceConfiguration,
          javascript = tsWorkspaceConfiguration,
          vtsls = {
            typescript = tsWorkspaceConfiguration,
            javascript = tsWorkspaceConfiguration,
            autoUseWorkspaceTsdk = false,
            tsserver = vim.tbl_deep_extend('force', { useSyntaxServer = 'always' }, hasVolar and {

              globalPlugins = {
                {
                  name = '@vue/typescript-plugin',
                  location = vim.fn.expand(
                    '$MASON/packages/vue-language-server/node_modules/@vue/language-server'
                  ),
                  languages = { 'vue', 'typescript' },
                  configNamespace = 'typescript',
                },
              },
            } or {}),
          },
          -- completions = {
          --   completeFunctionCalls = true,
          -- },
          -- diagnostics = {
          --   ignoredCodes = { 80006 },
          -- },
        },
        before_init = function(params, config)
          if params.rootUri then
            local root_path = vim.uri_to_fname(params.rootUri)
            local quotePreference = unanimous_var_for_root(root_path, 'quote_type') or 'auto'

            -- :lua local client = vim.lsp.get_clients({name = 'vtsls'})[1]; if client then print(client.config.settings.javascript.preferences.quoteStyle) else print("vtsls not found") end
            config.settings.javascript.preferences.quoteStyle = quotePreference
            config.settings.typescript.preferences.quoteStyle = quotePreference
          end
        end,
      })

      return true
    end),
    eslint = function()
      vim.lsp.config('eslint', {
        filetypes = {
          'astro',
          'javascript',
          'javascript.jsx',
          'javascriptreact',
          'json',
          'json5',
          'jsonc',
          'svelte',
          'toml',
          'typescript',
          'typescript.tsx',
          'typescriptreact',
          'vue',
          'yaml',
          'yaml.ansible',
        },
        capabilities = capabilities,
        settings = {
          workingDirectories = { mode = 'location' },
          -- experimental = {
          --   useFlatConfig = true,
          -- },
          useFlatConfig = true,
        },
        fix = {
          function(bufnr, client)
            local params = {
              command = 'eslint.applyAllFixes',
              arguments = {
                {
                  uri = vim.uri_from_bufnr(bufnr),
                  version = vim.lsp.util.buf_versions[bufnr],
                },
              },
            }

            client.request_sync('workspace/executeCommand', params, 3000, bufnr)
          end,
        },
      })

      return true
    end,
  }

  vim.schedule(function()
    vim.lsp.config('*', {
      capabilities = capabilities,
      -- root_markers = { '.git' },
    })

    for key, handler in pairs(handlers) do
      local value = handler()
      if value then vim.lsp.enable(key) end
    end

    -- dockerls, terraformls, volar, taplo, glslls, bashls, cssls,
    require('mason-lspconfig').setup({
      automatic_enable = {
        exclude = {
          'ts_ls',
        },
      },
      ensure_installed = {},
    })
  end)
end

return M
