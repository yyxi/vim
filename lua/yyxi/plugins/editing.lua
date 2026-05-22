local M = {}

local exclusions = require('yyxi.utilities.exclusions')

function M.autopairs()
  require('nvim-autopairs').setup({
    check_ts = true,
    enable_afterquote = true,
    enable_moveright = true,
    enable_check_bracket_line = true,
    disable_filetype = exclusions.autopairs_disabled_filetypes(),
  })

  -- local cmp_autopairs = require('nvim-autopairs.completion.cmp')
  -- local cmp = require('cmp')
  -- cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done())
end

function M.comment()
  -- Comment.nvim's public type marks defaulted fields as required.
  ---@diagnostic disable: missing-fields
  ---@type CommentConfig
  local opts = {
    toggler = {
      line = '<leader>cc',
      block = '<leader>cC',
    },
    opleader = {
      line = '<leader>c',
      block = '<leader>C',
    },
    extra = {
      above = '<leader>cO',
      below = '<leader>co',
      eol = '<leader>cA',
    },
    mappings = {
      basic = true,
      extra = true,
    },
    pre_hook = require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook(),
  }
  ---@diagnostic enable: missing-fields

  require('Comment').setup(opts)
end

function M.mini_ai()
  local ai = require('mini.ai')
  local ai_buffer = function(ai_type)
    local start_line, end_line = 1, vim.fn.line('$')
    if ai_type == 'i' then
      -- Skip first and last blank lines for `i` textobject
      local first_nonblank, last_nonblank =
        vim.fn.nextnonblank(start_line), vim.fn.prevnonblank(end_line)
      -- Do nothing for buffer with all blanks
      if first_nonblank == 0 or last_nonblank == 0 then
        return { from = { line = start_line, col = 1 } }
      end
      start_line, end_line = first_nonblank, last_nonblank
    end

    local to_col = math.max(vim.fn.getline(end_line):len(), 1)
    return {
      from = { line = start_line, col = 1 },
      to = { line = end_line, col = to_col },
    }
  end

  require('mini.ai').setup({
    n_lines = 1024,
    custom_textobjects = {
      o = ai.gen_spec.treesitter({ -- code block
        a = { '@block.outer', '@conditional.outer', '@loop.outer' },
        i = { '@block.inner', '@conditional.inner', '@loop.inner' },
      }),
      a = ai.gen_spec.treesitter({ -- code block
        a = '@parameter.inner',
        i = '@parameter.inner',
      }),
      f = ai.gen_spec.treesitter({
        a = '@function.outer',
        i = '@function.inner',
      }), -- function
      C = ai.gen_spec.treesitter({ a = '@class.outer', i = '@class.inner' }), -- class
      c = ai.gen_spec.treesitter({ a = '@call.outer', i = '@call.inner' }),
      t = { '<([%p%w]-)%f[^<%w][^<>]->.-</%1>', '^<.->().*()</[^/]->$' }, -- tags
      d = { '%f[%d]%d+' }, -- digits
      e = { -- Word with case
        {
          '%u[%l%d]+%f[^%l%d]',
          '%f[%S][%l%d]+%f[^%l%d]',
          '%f[%P][%l%d]+%f[^%l%d]',
          '^[%l%d]+%f[^%l%d]',
        },
        '^().*()$',
      },
      g = ai_buffer, -- buffer
      u = ai.gen_spec.function_call(), -- u for "Usage"
      U = ai.gen_spec.function_call({ name_pattern = '[%w_]' }), -- without dot in function name
    },
    mappings = {
      around = 'a',
      inside = 'i',
      around_next = 'an',
      around_last = 'aN',
      inside_next = 'in',
      inside_last = 'iN',
      goto_left = '',
      goto_right = '',
    },
  })
end

function M.mini_align()
  require('mini.align').setup({
    mappings = {
      start = '',
      start_with_preview = '<leader>a',
    },
  })
end

function M.mini_surround()
  local opts = {
    mappings = {
      add = '<leader>sa', -- Add surrounding in Normal and Visual modes
      delete = '<leader>sd', -- Delete surrounding
      find = '<leader>sf', -- Find surrounding (to the right)
      find_left = '<leader>sF', -- Find surrounding (to the left)
      highlight = '', -- Highlight surrounding
      replace = '<leader>sr', -- Replace surrounding
      update_n_lines = '<leader>sn', -- Update `n_lines`
      suffix_last = '', -- Suffix to search with "prev" method
      suffix_next = '', -- Suffix to search with "next" method
    },
    n_lines = 500,
  }

  -- opts.custom_surroundings = nil
  require('mini.surround').setup(opts)
end

function M.neogen() require('neogen').setup({ snippet_engine = 'luasnip' }) end

function M.text_case()
  require('textcase').setup({
    default_keymappings_enabled = true,
    prefix = '<leader>n',
  })
end

function M.treesj()
  local opts = { use_default_keymaps = false, max_join_length = 150 }

  require('treesj').setup(opts)
end

function M.yanky()
  require('yanky').setup({
    ring = {
      history_length = 100,
      storage = 'shada',
      sync_with_numbered_registers = true,
      cancel_event = 'update',
    },
    picker = {
      select = {
        action = nil, -- nil to use default put action
      },
      telescope = {
        mappings = nil, -- nil to use default mappings
      },
    },
    system_clipboard = {
      sync_with_ring = true,
    },
    highlight = {
      on_put = false,
      on_yank = true,
      timer = 200,
    },
    preserve_cursor_position = {
      enabled = true,
    },
    textobj = {
      enabled = false,
    },
  })
end

return M
