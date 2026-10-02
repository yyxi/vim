-- Load the reviewed configuration and exercise Neovim's Python provider.
local repository = assert(arg[1], 'repository required')
vim.opt.runtimepath:prepend(repository)
dofile(repository .. '/init.lua')
assert(vim.fn.has('python3') == 1, 'Python provider unavailable')
vim.cmd('qa!')
