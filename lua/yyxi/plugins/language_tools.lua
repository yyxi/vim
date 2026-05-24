local M = {}

local environment = require('yyxi.utilities.environment')

function M.conform()
  ---@type conform.setupOpts
  local opts = {
    formatters_by_ft = {
      javascript = { 'prettier' },
      json = { 'prettier' },
      json5 = { 'prettier' },
      jsonc = { 'prettier' },
      -- lua = { 'stylua' },
      tex = { 'latexindent' },
      markdown = { 'prettier' },
      sh = { 'shfmt' },
      typescript = { 'prettier' },
      typescriptreact = { 'prettier' },
      css = { 'prettier' },
      vue = { 'prettier' },
      yaml = { 'prettier' },
    },
    formatters = {
      shfmt = {
        prepend_args = { '-i', '2' },
      },
    },
  }

  require('conform').setup(opts)
end

local function configure_lua_ls_workspace(_, config)
  local root_dir = config.root_dir
  if not root_dir then return end

  local config_root = environment.normalize_path(environment.repository_root())
  if not environment.is_path_within(root_dir, config_root) then return end

  config.settings = vim.tbl_deep_extend('force', config.settings or {}, {
    Lua = {
      workspace = {
        library = environment.luarc_workspace_libraries(config_root),
      },
    },
  })
end

function M.gtd()
  ---@diagnostic disable-next-line: missing-fields
  require('gtd').setup({})
end

function M.lsp_fix()
  local fix = require('lsp-fix')

  fix.setup({
    json5 = {
      order = {
        'eslint',
      },
    },
    jsonc = {
      order = {
        'eslint',
      },
    },
    toml = {
      order = {
        'taplo',
        'eslint',
      },
    },
    json = {
      order = {
        'eslint',
      },
    },
    yaml = {
      order = {
        'eslint',
      },
    },
    typescript = {
      order = {
        'ts_ls',
        'vtsls',
        'eslint',
      },
    },
    dockerfile = {
      order = {
        'dockerls',
      },
    },
    python = {
      order = {
        'ty',
        'pyright',
        'ruff',
      },
    },
    vue = {
      order = {
        'volar',
        'eslint',
      },
    },
    -- css = {
    --   order = { 'stylelint_lsp' },
    --   tab_width = function()
    --     return vim.opt.shiftwidth:get()
    --   end,
    -- }
  })
end

function M.none_ls()
  local is_installed = environment.has_executable

  local null_ls = require('null-ls')
  null_ls.setup({
    sources = {
      -- https://github.com/nvimtools/none-ls.nvim/blob/main/doc/BUILTINS.md
      null_ls.builtins.diagnostics.actionlint.with({
        condition = function() return is_installed('actionlint') end,
      }),
      null_ls.builtins.diagnostics.fish.with({
        condition = function() return is_installed('fish') end,
      }),
      null_ls.builtins.diagnostics.hadolint.with({
        condition = function() return is_installed('hadolint') end,
      }),
    },
  })
end

local function concat(first, second) return vim.list_extend(first, second) end

local function ternary(condition, true_value, false_value)
  return condition and true_value or false_value
end

function M.lsp()
  local is_installed = environment.has_executable

  vim.lsp.log.set_level('ERROR')

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
    ansiblels = ternary(
      is_installed('ansible-language-server') and is_installed('ansible-config'),
      function()
        vim.lsp.config('ansiblels', {
          capabilities = capabilities,
          settings = {
            ansible = {
              python = {
                interpreterPath = 'python3',
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
      end
    ),
    yamlls = ternary(is_installed('yaml-language-server'), function()
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
    end),
    jsonls = ternary(is_installed('vscode-json-language-server'), function()
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
    end),
    lua_ls = ternary(is_installed('lua-language-server'), function()
      vim.lsp.config('lua_ls', {
        capabilities = capabilities,
        before_init = configure_lua_ls_workspace,
      })

      return true
    end),
    ty = ternary(is_installed('ty'), function()
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
    end),
    pyright = ternary(is_installed('pyright-langserver'), function()
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
    end),
    ruff = ternary(is_installed('ruff'), function()
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
    end),
    vtsls = ternary(is_installed('vtsls'), function()
      local vue_language_server_path =
        environment.node_package_path('@vue/language-server', environment.repository_root())
      local hasVolar = is_installed('vue-language-server') and vue_language_server_path ~= nil

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
                  location = vue_language_server_path,
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
    eslint = ternary(is_installed('vscode-eslint-language-server'), function()
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
    end),
    cssls = ternary(is_installed('vscode-css-language-server'), function()
      vim.lsp.config('cssls', {
        capabilities = capabilities,
      })

      return true
    end),
    html = ternary(is_installed('vscode-html-language-server'), function()
      vim.lsp.config('html', {
        capabilities = capabilities,
      })

      return true
    end),
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
  end)
end

function M.lean()
  ---@type lean.Config
  local opts = { -- see below for full configuration options
    mappings = false,
    infoview = {
      autoopen = false,
    },
    progress_bars = {
      enable = false,
    },
    stderr = {
      enable = false,
    },
  }

  require('lean').setup(opts)
end

return M
