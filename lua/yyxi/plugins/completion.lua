local M = {}

function M.setup()
  local cmp = require('blink.cmp')
  local environment = require('yyxi.utilities.environment')
  local luasnip = require('luasnip')

  local blink_fuzzy_library = environment.join_path({
    environment.git_worktree_path('blink.cmp'),
    'target',
    'release',
    package.config:sub(1, 1) == '\\' and 'blink_cmp_fuzzy.dll' or 'libblink_cmp_fuzzy.so',
  })
  if jit.os:lower() == 'mac' or jit.os:lower() == 'osx' then
    blink_fuzzy_library = environment.join_path({
      environment.git_worktree_path('blink.cmp'),
      'target',
      'release',
      'libblink_cmp_fuzzy.dylib',
    })
  end
  local blink_has_rust_fuzzy = environment.exists(blink_fuzzy_library)

  luasnip.config.setup()

  require('luasnip.loaders.from_vscode').lazy_load({
    exclude = { 'html' },
  })

  local has_words_before = function()
    local col = vim.api.nvim_win_get_cursor(0)[2]
    if col == 0 then return false end
    local line = vim.api.nvim_get_current_line()
    return line:sub(col, col):match('%s') == nil
  end

  ---@type blink.cmp.Config
  local opts = {
    snippets = { preset = 'luasnip' },
    keymap = {
      preset = 'none',
      ['<Up>'] = { 'select_prev', 'fallback' },
      ['<Down>'] = { 'select_next', 'fallback' },
      ['<CR>'] = { 'accept', 'fallback' },
      ['<Tab>'] = {
        function(cmp)
          if
            not cmp.snippet_active({ direction = 1 })
            and has_words_before()
            and not cmp.is_visible()
          then
            return cmp.show()
          end
        end,
        'snippet_forward',
        'select_next',
        'fallback',
      },
      ['<S-Tab>'] = { 'snippet_backward', 'select_prev', 'fallback' },
      ['<Esc>'] = {
        function(cmp)
          if cmp.is_menu_visible() then cmp.hide() end
          if cmp.snippet_active() then require('luasnip').unlink_current() end
        end,
        'fallback',
      },
    },
    appearance = {
      use_nvim_cmp_as_default = true,
      -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
      -- Adjusts spacing to ensure icons are aligned
      nerd_font_variant = 'mono',
    },
    -- signature = { enabled = true },
    completion = {
      documentation = {
        auto_show = true,
        auto_show_delay_ms = 50,
        window = { border = 'rounded' },
      },
      trigger = {
        show_in_snippet = false,
      },
      list = {
        cycle = {
          from_bottom = true,
          from_top = true,
        },
        selection = {
          preselect = false,
          -- preselect = function(ctx)
          --   return not cmp.snippet_active()
          -- end,
          auto_insert = function() return not cmp.snippet_active() end,
          -- auto_insert = false
        },
      },
      ghost_text = {
        enabled = false,
      },
      menu = {
        border = 'rounded',
        winblend = 10,
        draw = {
          padding = { 1, 1 },
          columns = {
            { 'label' },
            { 'label_description' },
            { 'source_name' },
          },
          components = {
            source_name = {
              text = function(ctx)
                local source_name = ctx.source_name

                if source_name == 'Snippets' then return '∫' end

                if source_name == 'LSP' then return '∴' end

                if source_name == 'Path' then return '☇' end

                if source_name == 'Buffer' then return '…' end

                return source_name
              end,
            },
            -- label_description = {
            --   width = { fill = true, max = 60 },
            -- },
            label = {
              width = { fill = true, max = 60 },
              text = function(ctx) return ctx.label .. (ctx.label_detail or '') end,
              highlight = function(ctx)
                -- label and label details
                local highlights = {
                  {
                    0,
                    #ctx.label,
                    group = ctx.deprecated and 'BlinkCmpLabelDeprecated' or 'BlinkCmpLabel',
                  },
                }
                if ctx.label_detail then
                  table.insert(highlights, {
                    #ctx.label,
                    #ctx.label + #ctx.label_detail,
                    group = 'BlinkCmpLabelDetail',
                  })
                end

                return highlights
              end,
            },
          },
        },
      },
    },
    sources = {
      default = { 'lsp', 'path', 'snippets', 'buffer' },
    },
    fuzzy = {
      sorts = {
        'exact',
        -- defaults
        'score',
        'sort_text',
      },
      implementation = blink_has_rust_fuzzy and 'prefer_rust' or 'lua',
      prebuilt_binaries = {
        download = false,
      },
    },
    cmdline = {
      enabled = true,
      keymap = {
        preset = 'none',
        ['<Up>'] = { 'select_prev', 'fallback' },
        ['<Down>'] = { 'select_next', 'fallback' },
        ['<CR>'] = { 'accept', 'fallback' },
        ['<Tab>'] = {
          function()
            if not (vim.fn.getcmdtype() == ':' or vim.fn.getcmdtype() == '!') then return true end
          end,
          function(cmp)
            if has_words_before() and not cmp.is_visible() then return cmp.show() end
          end,
          'show_and_insert',
          'select_next',
        },
        ['<S-Tab>'] = {
          function()
            if not (vim.fn.getcmdtype() == ':' or vim.fn.getcmdtype() == '!') then return true end
          end,
          'show_and_insert',
          'select_prev',
        },
        ['<Esc>'] = {
          function(cmp)
            if cmp.is_menu_visible() then
              cmp.hide()
              -- return true
            else
              vim.api.nvim_feedkeys(
                vim.api.nvim_replace_termcodes('<C-c>', true, false, true),
                'n',
                true
              )
            end
          end,
        },
      },
      completion = {
        list = {
          selection = {
            preselect = false,
            auto_insert = true,
          },
        },
        menu = {
          draw = {
            columns = {
              { 'label' },
            },
          },
          -- auto_show = function()
          --   return vim.fn.getcmdtype() == ':' or vim.fn.getcmdtype() == '!'
          -- end,
          auto_show = false,
        },
        ghost_text = {
          enabled = false,
        },
      },
    },
  }

  cmp.setup(opts)
end

return M
