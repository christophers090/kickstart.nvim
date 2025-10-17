-- Adds git related signs to the gutter, as well as utilities for managing changes
-- NOTE: Keymaps are configured in lua/custom/keymaps.lua via autocmd

return {
  {
    'lewis6991/gitsigns.nvim',
    opts = {
      on_attach = function(bufnr)
        -- Trigger our custom autocmd that has the keymaps
        vim.api.nvim_exec_autocmds('User', { pattern = 'GitSignsAttach', data = { buf = bufnr } })
      end,
    },
  },
}
