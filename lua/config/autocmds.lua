-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- Force relative line numbers everywhere
vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWinEnter', 'WinEnter', 'TermOpen' }, {
  desc = 'Enable relative line numbers everywhere',
  group = vim.api.nvim_create_augroup('force-relative-numbers', { clear = true }),
  callback = function()
    vim.wo.number = true
    vim.wo.relativenumber = true
  end,
})

-- Show relative line numbers in terminal normal mode
vim.api.nvim_create_autocmd('TermEnter', {
  callback = function()
    vim.wo.relativenumber = false
    vim.wo.number = false
  end,
})

vim.api.nvim_create_autocmd('TermLeave', {
  callback = function()
    vim.wo.relativenumber = true
    vim.wo.number = true
  end,
})

-- Automatically enter insert mode when focusing a terminal buffer or opening one
vim.api.nvim_create_autocmd({ 'BufEnter', 'TermOpen' }, {
  pattern = { 'term://*' },
  callback = function()
    vim.cmd('startinsert')
  end,
})

-- Detect Bazel files by filename
vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
  pattern = { 'BUILD', 'BUILD.bazel', 'WORKSPACE', 'WORKSPACE.bazel', '*.bzl' },
  callback = function()
    vim.bo.filetype = 'starlark'
  end,
})


