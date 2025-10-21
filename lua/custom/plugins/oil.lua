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
    keymaps = {
      -- Disable oil's default <C-l> so window navigation works
      ['<C-l>'] = false,
      ['<C-h>'] = false,
      ['<C-k>'] = false,
      ['<C-j>'] = false,
      -- Override default <CR> to open files in a split to the right
      ['<CR>'] = function()
        local oil = require('oil')
        local entry = oil.get_cursor_entry()
        
        -- If it's a directory, use default behavior (navigate into it)
        if entry and entry.type == 'directory' then
          oil.select()
          return
        end
        
        -- For files, get the full path and open it in the right window
        local dir = oil.get_current_dir()
        if not dir or not entry then
          return
        end
        
        local filepath = dir .. entry.name
        local current_win = vim.api.nvim_get_current_win()
        
        -- Try to move to the window on the right
        vim.cmd('wincmd l')
        local new_win = vim.api.nvim_get_current_win()
        
        if new_win == current_win then
          -- No window to the right, create a new vertical split
          vim.cmd('vsplit')
        end
        
        -- Open the file in the current window (which is now the right window)
        vim.cmd('edit ' .. vim.fn.fnameescape(filepath))
        
        -- Go back to oil window
        vim.api.nvim_set_current_win(current_win)
      end,
    },
  },
}


