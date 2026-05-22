local M = {}

function M.setup()
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

return M
