return {
  'nvim-pack/nvim-spectre',
  dependencies = {
    'nvim-lua/plenary.nvim',
  },
  config = function()
    require('spectre').setup({
      highlight = {
        ui = 'String',
        search = 'IncSearch',
        replace = 'DiffAdd',
      },
      replace_engine = {
        ['sed'] = {
          cmd = 'sed',
          args = nil,
        },
      },
      mapping = {
        ['run_replace'] = {
          map = '<leader>r',
          cmd = "<cmd>lua require('spectre.actions').run_replace()<CR>",
          desc = 'replace all',
        },
      },
    })
  end,
}

