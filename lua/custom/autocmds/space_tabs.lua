-- Detect Bazel files by filename
vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
  pattern = { 'BUILD', 'BUILD.bazel', 'WORKSPACE', 'WORKSPACE.bazel', '*.bzl' },
  callback = function()
    vim.bo.filetype = 'starlark'
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'cpp', 'c' },
  callback = function()
    vim.opt_local.expandtab = true -- Use spaces instead of tabs
    vim.opt_local.shiftwidth = 2 -- Indent by 2 spaces
    vim.opt_local.tabstop = 2 -- Tab key inserts 2 spaces
    vim.opt_local.softtabstop = 2 -- Backspace deletes 2 spaces
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'starlark', 'bazel' },
  callback = function()
    vim.opt_local.expandtab = true -- Use spaces instead of tabs
    vim.opt_local.shiftwidth = 4 -- Indent by 4 spaces
    vim.opt_local.tabstop = 4 -- Tab key inserts 4 spaces
    vim.opt_local.softtabstop = 4 -- Backspace deletes 4 spaces
  end,
})
