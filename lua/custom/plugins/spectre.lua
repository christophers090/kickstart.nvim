return {
  'nvim-pack/nvim-spectre',
  dependencies = {
    'nvim-lua/plenary.nvim',
  },
  keys = {
    {
      '<leader>S',
      function()
        require('spectre').toggle()
      end,
      desc = 'Toggle [S]pectre (find and replace)',
    },
    {
      '<leader>sr',
      function()
        require('spectre').open_visual({ select_word = true })
      end,
      desc = '[S]earch and [R]eplace current word',
    },
    {
      '<leader>sr',
      function()
        require('spectre').open_visual()
      end,
      mode = 'v',
      desc = '[S]earch and [R]eplace selection',
    },
    {
      '<leader>si',
      function()
        require('spectre').open_file_search({ select_word = true })
      end,
      desc = '[S]earch and replace in current file',
    },
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

