return {
  'stevearc/oil.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  -- Load on keypress
  keys = {
    { '<leader>o', function()
        vim.cmd('topleft vsplit')
        require('oil').open()
        vim.cmd('vertical resize 40')
      end, desc = 'Open Oil to the side' },
  },
  opts = {
    -- Keep Neo-tree as the primary explorer; invoke Oil explicitly via keys
    default_file_explorer = false,
    columns = { 'icon' },
    view_options = {
      show_hidden = true,
    },
  },
}


