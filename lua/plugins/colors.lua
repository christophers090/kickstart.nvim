return {
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    lazy = false,
    priority = 1000,
    config = function()
      local ok, catppuccin = pcall(require, 'catppuccin')
      if ok then
        catppuccin.setup {
          flavour = 'mocha',
        }
      end

      -- Always start in catppuccin-mocha
      local theme_ok = pcall(vim.cmd.colorscheme, 'catppuccin-mocha')
      if not theme_ok then
        vim.notify('Failed to load theme: catppuccin-mocha. Falling back to default.', vim.log.levels.WARN)
        pcall(vim.cmd.colorscheme, 'default')
      end

      -- <leader>tl: switch to dark_flat
      vim.keymap.set('n', '<leader>tl', function()
        pcall(vim.cmd.colorscheme, 'dark_flat')
        vim.notify('Theme: dark_flat', vim.log.levels.INFO)
      end, { desc = '[T]heme dark_f[L]at' })

      -- <leader>tr: return to catppuccin-mocha
      vim.keymap.set('n', '<leader>tr', function()
        local ok2 = pcall(vim.cmd.colorscheme, 'catppuccin-mocha')
        if not ok2 then
          vim.notify('Failed to load theme: catppuccin-mocha.', vim.log.levels.WARN)
          return
        end
        vim.notify('Theme: catppuccin-mocha', vim.log.levels.INFO)
      end, { desc = '[T]heme [R]eturn (catppuccin-mocha)' })
    end,
  },
  {
    'sekke276/dark_flat.nvim',
    lazy = false,
    priority = 1000,
  },
}
