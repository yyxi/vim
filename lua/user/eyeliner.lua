require('eyeliner').setup({
  highlight_on_key = false, -- this must be set to true for dimming to work!
  dim = false,
})

vim.api.nvim_set_hl(0, 'EyelinerPrimary', { bold = true, underline = true })
vim.api.nvim_set_hl(0, 'EyelinerSecondary', { underline = true })
