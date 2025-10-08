return {
  'folke/zen-mode.nvim',
  opts = {
    window = {
      backdrop = 0.95,
      width = 120,
      height = 1,
      options = {
        number = true,
        relativenumber = true,
      },
    },
    plugins = {
      options = {
        enabled = true,
        ruler = false,
        showcmd = false,
        laststatus = 0,
      },
    },
    on_open = function(win)
      -- Track which windows exist before zen mode
      vim.g.zen_original_wins = vim.api.nvim_list_wins()
    end,
    on_close = function()
      -- Get the buffer that was shown in zen mode
      local zen_buf = vim.api.nvim_get_current_buf()
      
      -- After zen closes, vim restores the original window layout
      -- We need to set all the restored windows to show the zen buffer
      vim.schedule(function()
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          -- Only update normal windows, not floating
          if vim.api.nvim_win_get_config(win).relative == '' then
            vim.api.nvim_win_set_buf(win, zen_buf)
            break -- Just set the first normal window
          end
        end
      end)
    end,
  },
}
