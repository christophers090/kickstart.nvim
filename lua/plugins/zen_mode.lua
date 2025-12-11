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
      vim.g.zen_original_wins = vim.api.nvim_list_wins()
      -- Capture the parent window (alternate window #)
      vim.g.zen_parent_win = vim.fn.win_getid(vim.fn.winnr('#'))
      -- Track the current buffer in the Zen window
      vim.g.zen_last_buf = vim.api.nvim_get_current_buf()
      
      -- Create an autocmd to update zen_last_buf when buffer changes in Zen window
      local group = vim.api.nvim_create_augroup('ZenModeTrack', { clear = true })
      vim.api.nvim_create_autocmd('BufEnter', {
        group = group,
        callback = function()
          if vim.api.nvim_get_current_win() == win then
            vim.g.zen_last_buf = vim.api.nvim_get_current_buf()
          end
        end,
      })
    end,
    on_close = function()
      local zen_buf = vim.g.zen_last_buf or vim.api.nvim_get_current_buf()
      local parent_win = vim.g.zen_parent_win
      
      -- Clear tracking autocmds
      pcall(vim.api.nvim_del_augroup_by_name, 'ZenModeTrack')

      vim.schedule(function()
        if parent_win and vim.api.nvim_win_is_valid(parent_win) then
          vim.api.nvim_win_set_buf(parent_win, zen_buf)
        else
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            if vim.api.nvim_win_get_config(win).relative == '' then
              vim.api.nvim_win_set_buf(win, zen_buf)
              break
            end
          end
        end
      end)
    end,
  },
}
