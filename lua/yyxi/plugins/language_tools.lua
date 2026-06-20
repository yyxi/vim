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
      lua = { 'stylua' },
      tex = { 'latexindent' },
      markdown = { 'prettier' },
      go = {},
      rust = {},
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

function M.lsp_format()
  local format = require('yyxi.lsp.format')

  format.setup({
    -- TOML buffers attach both tombi (Rust LSP) and vscode-eslint-language-server,
    -- and conform iterates attached clients by `client.id` (startup race). Pin
    -- the order so tombi formats first and eslint applies project rules after.
    toml = {
      order = {
        'tombi',
        'eslint',
      },
    },
  })
end

function M.lsp_fix()
  local fix = require('yyxi.lsp.fix')

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
        'tombi',
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
    ['yaml.ansible'] = {
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
    go = {
      order = {
        'gopls',
      },
    },
    python = {
      order = {
        { 'ty', 'pyright' },
        'ruff',
      },
    },
    vue = {
      order = {
        'vtsls',
        'eslint',
      },
    },
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

local function ensure_vtsls_global_plugin(config, plugin)
  local settings = config.settings or {}
  config.settings = settings

  local vtsls_settings = settings.vtsls or {}
  settings.vtsls = vtsls_settings

  local tsserver_settings = vtsls_settings.tsserver or {}
  vtsls_settings.tsserver = tsserver_settings

  local global_plugins = tsserver_settings.globalPlugins
  if type(global_plugins) ~= 'table' then
    tsserver_settings.globalPlugins = { plugin }
    return
  end

  for _, existing_plugin in ipairs(global_plugins) do
    if type(existing_plugin) == 'table' and existing_plugin.name == plugin.name then return end
  end

  table.insert(global_plugins, plugin)
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

  M.lsp_fix()
  M.lsp_format()

  local fix = require('yyxi.lsp.fix')

  local function versioned_document_argument(bufnr)
    return {
      uri = vim.uri_from_bufnr(bufnr),
      version = vim.lsp.util.buf_versions[bufnr],
    }
  end

  ---@alias yyxi.plugins.language_tools.CommandArguments lsp.LSPAny[]

  ---@param command string
  ---@param arguments yyxi.plugins.language_tools.CommandArguments | fun(ctx: yyxi.lsp.fix.Context): yyxi.plugins.language_tools.CommandArguments
  ---@param timeout_ms? integer
  ---@return yyxi.lsp.fix.Handler
  local function workspace_command_handler(command, arguments, timeout_ms)
    return function(ctx)
      local resolved_arguments ---@type yyxi.plugins.language_tools.CommandArguments
      if type(arguments) == 'function' then
        resolved_arguments = arguments(ctx)
      else
        resolved_arguments = arguments
      end

      return fix.execute_workspace_command(ctx, {
        command = command,
        arguments = resolved_arguments,
      }, timeout_ms)
    end
  end

  local function gopls_code_action_handler(action_kind, timeout_ms)
    return function(ctx)
      local namespace = vim.lsp.diagnostic.get_namespace(ctx.client.id)
      local diagnostics = vim.lsp.diagnostic.from(vim.diagnostic.get(ctx.bufnr, {
        namespace = namespace,
      }))

      return fix.execute_code_action_kind(ctx, action_kind, timeout_ms, diagnostics)
    end
  end

  fix.register('gopls', {
    gopls_code_action_handler('source.fixAll', 3000),
    gopls_code_action_handler('source.organizeImports', 3000),
  })

  fix.register('pyright', {
    workspace_command_handler(
      'pyright.organizeimports',
      function(ctx) return { vim.uri_from_bufnr(ctx.bufnr) } end,
      3000
    ),
  })

  fix.register('ruff', {
    workspace_command_handler(
      'ruff.applyOrganizeImports',
      function(ctx) return { versioned_document_argument(ctx.bufnr) } end,
      3000
    ),
    workspace_command_handler(
      'ruff.applyAutofix',
      function(ctx) return { versioned_document_argument(ctx.bufnr) } end,
      3000
    ),
  })

  fix.register('vtsls', {
    workspace_command_handler(
      'typescript.organizeImports',
      function(ctx) return { vim.api.nvim_buf_get_name(ctx.bufnr) } end,
      3000
    ),
    workspace_command_handler(
      'typescript.sortImports',
      function(ctx) return { vim.api.nvim_buf_get_name(ctx.bufnr) } end,
      3000
    ),
  })

  fix.register('eslint', {
    workspace_command_handler(
      'eslint.applyAllFixes',
      function(ctx) return { versioned_document_argument(ctx.bufnr) } end,
      3000
    ),
  })

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

  local function harper_config(filetypes, linters)
    return {
      cmd = { 'harper-ls', '--stdio' },
      root_markers = { '.harper-dictionary.txt', '.git' },
      capabilities = capabilities,
      filetypes = filetypes,
      settings = {
        ['harper-ls'] = {
          userDictPath = '',
          fileDictPath = '',
          linters = linters,
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
    }
  end

  local harper_prose_linters = {
    EllipsisLength = false,
    LongSentences = false,
    PhrasalVerbAsCompoundNoun = false,
    SentenceCapitalization = false,
    Spaces = false,
    SpellCheck = false,
    SpelledNumbers = false,
    WrongQuotes = false,
    UseTitleCase = false,
  }

  local harper_code_linters = vim.tbl_extend('force', harper_prose_linters, {
    DisjointPrefixes = false,
    ExpandAlloc = false,
    ExpandArgument = false,
    ExpandBecause = false,
    ExpandControl = false,
    ExpandDecl = false,
    ExpandDependencies = false,
    ExpandDeref = false,
    ExpandForward = false,
    ExpandGovt = false,
    ExpandMemoryShorthands = false,
    ExpandMinimum = false,
    ExpandParameter = false,
    ExpandPeople = false,
    ExpandPointer = false,
    ExpandPrevious = false,
    ExpandStandardInputAndOutput = false,
    ExpandThrough = false,
    ExpandTimeShorthands = false,
    ExpandWith = false,
    ExpandWithout = false,
    InflectedVerbAfterTo = false,
    MergeWords = false,
    NumericRangeEnDash = false,
    OrthographicConsistency = false,
    OxfordComma = false,
    SplitWords = false,
    ToDoHyphen = false,
    ToTwoToo = false,
  })

  local handlers = {
    harper_ls = ternary(is_installed('harper-ls'), function()
      vim.lsp.config(
        'harper_ls',
        harper_config({
          'gitcommit',
          'markdown',
          'text',
        }, harper_prose_linters)
      )

      return true
    end),
    harper_ls_code = ternary(is_installed('harper-ls'), function()
      vim.lsp.config(
        'harper_ls_code',
        harper_config({
          'c',
          'cpp',
          'go',
          'haskell',
          'javascript',
          'javascriptreact',
          'lua',
          'nix',
          'python',
          'rust',
          'sh',
          'swift',
          'toml',
          'typescript',
          'typescriptreact',
          'zig',
        }, harper_code_linters)
      )

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
        handlers = { ['vscode/content'] = require('yyxi.lsp.schema_content_handler').handler },
        settings = {
          yaml = {
            schemas = require('yyxi.utilities.offline_schemas').yaml.schemas(),
            schemaStore = { enable = false },
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
        on_init = function(client)
          -- Tell yamlls to forward every http(s) schema request to us as a
          -- vscode/content request. Without this, yamlls calls request_light
          -- directly and produces ENOTFOUND diagnostics when offline.
          client:notify('yaml/registerContentRequest')
        end,
      })

      return true
    end),
    jsonls = ternary(is_installed('vscode-json-language-server'), function()
      vim.lsp.config('jsonls', {
        capabilities = capabilities,
        handlers = { ['vscode/content'] = require('yyxi.lsp.schema_content_handler').handler },
        init_options = {
          provideFormatter = true,
          -- Only `file` is handled server-side; http(s) URLs are routed back to
          -- us via `vscode/content`, where we serve vendored content or `{}`.
          handledSchemaProtocols = { 'file' },
        },
        settings = {
          json = {
            schemas = require('yyxi.utilities.offline_schemas').json.schemas(),
            schemaDownload = { enable = false },
            validate = { enable = true },
          },
        },
      })

      return true
    end),
    tombi = ternary(is_installed('tombi'), function()
      vim.lsp.config('tombi', {
        capabilities = capabilities,
        -- --offline is a hard guard inside Tombi: every http(s) schema fetch is
        -- short-circuited before it leaves the process. No vscode/content
        -- handler is needed, in contrast to jsonls/yamlls above.
        --
        -- Schema associations are pushed at attach time via tombi/associateSchema,
        -- sourced from the same offline catalog as jsonls/yamlls. See
        -- lua/yyxi/lsp/tombi_schema_overlay.lua. The user's project-level
        -- tombi.toml still wins, since our entries use the default `force = false`.
        cmd = { 'tombi', 'lsp', '--offline' },
        filetypes = { 'toml' },
        root_markers = {
          'tombi.toml',
          '.tombi.toml',
          'pyproject.toml',
          'Cargo.toml',
          '.git',
        },
        on_init = function(client) require('yyxi.lsp.tombi_schema_overlay').attach(client) end,
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
    gopls = ternary(is_installed('gopls'), function()
      vim.lsp.config('gopls', {
        capabilities = capabilities,
        settings = {
          gopls = {
            analyses = {
              unusedparams = true,
            },
            staticcheck = true,
            usePlaceholders = true,
            gofumpt = true,
            vulncheck = 'Imports',
          },
        },
      })

      return true
    end),
    rust_analyzer = ternary(is_installed('rust-analyzer'), function()
      local rust_analyzer_settings = {
        cargo = {
          allTargets = true,
          autoreload = true,
          buildScripts = {
            enable = true,
          },
        },
        procMacro = {
          enable = true,
        },
      }

      if is_installed('cargo-clippy') then
        rust_analyzer_settings.check = {
          command = 'clippy',
          extraArgs = { '--no-deps' },
        }
      end

      vim.lsp.config('rust_analyzer', {
        capabilities = capabilities,
        settings = {
          ['rust-analyzer'] = rust_analyzer_settings,
        },
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
      })

      return true
    end),
    ruff = ternary(is_installed('ruff'), function()
      vim.lsp.config('ruff', {
        capabilities = capabilities,
      })

      return true
    end),
    vtsls = ternary(is_installed('vtsls'), function()
      local vue_language_server_path =
        environment.node_package_path('@vue/language-server', environment.repository_root())
      local can_use_vue_typescript_plugin = is_installed('vue-language-server')
        and vue_language_server_path ~= nil
      local vue_typescript_plugin = can_use_vue_typescript_plugin
          and {
            name = '@vue/typescript-plugin',
            location = vue_language_server_path,
            languages = { 'vue', 'typescript' },
            configNamespace = 'typescript',
          }
        or nil

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
        filetypes = concat({
          'typescript',
          'javascript',
          'javascriptreact',
          'typescriptreact',
        }, can_use_vue_typescript_plugin and { 'vue' } or {}),
        -- init_options = {},
        settings = {
          typescript = tsWorkspaceConfiguration,
          javascript = tsWorkspaceConfiguration,
          vtsls = {
            typescript = tsWorkspaceConfiguration,
            javascript = tsWorkspaceConfiguration,
            autoUseWorkspaceTsdk = false,
            tsserver = {
              useSyntaxServer = 'always',
            },
          },
          -- completions = {
          --   completeFunctionCalls = true,
          -- },
          -- diagnostics = {
          --   ignoredCodes = { 80006 },
          -- },
        },
        before_init = function(params, config)
          if vue_typescript_plugin then
            ensure_vtsls_global_plugin(config, vue_typescript_plugin)
          end

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
