return {
  'NeogitOrg/neogit',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'sindrets/diffview.nvim',
    'nvim-telescope/telescope.nvim',
  },
  config = function()
    require('neogit').setup({
      integrations = {
        telescope = true,
        diffview = true,
      },
    })
    
    -- Keymaps
    vim.keymap.set('n', '<leader>gs', '<cmd>Neogit<cr>', { desc = 'Open Neogit' })
    vim.keymap.set('n', '<leader>gc', '<cmd>Neogit commit<cr>', { desc = 'Neogit commit' })
    vim.keymap.set('n', '<leader>gp', '<cmd>Neogit pull<cr>', { desc = 'Neogit pull' })
    vim.keymap.set('n', '<leader>gP', '<cmd>Neogit push<cr>', { desc = 'Neogit push' })
  end,
}

