-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim

return {
  'nvim-neo-tree/neo-tree.nvim',
  version = '*',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
    'MunifTanjim/nui.nvim',
  },
  lazy = false,
  keys = {
    { '\\', ':Neotree reveal<CR>', desc = 'NeoTree reveal', silent = true },
  },
  opts = {
    enable_git_status = true,
    enable_diagnostics = true,
    filesystem = {
      window = {
        position = 'left',
        width = 40,
        mappings = {
          ['\\'] = 'close_window',
          ['<leader>a'] = function(state)
            local node = state.tree:get_node()
            if node.type == 'file' then
              -- Open the file first
              vim.cmd('edit ' .. node.path)
              -- Add to harpoon
              require('harpoon'):list():add()
            end
          end,
        },
      },
    },
    window = {
      mappings = {
        ['\\'] = 'close_window',
      },
    },
    event_handlers = {
      {
        event = 'neo_tree_buffer_enter',
        handler = function()
          vim.cmd('setlocal relativenumber')
        end,
      },
    },
  },
}
