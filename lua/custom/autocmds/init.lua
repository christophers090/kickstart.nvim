require 'custom.autocmds.space_tabs'

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

