return {
  { -- Adds git related signs to the gutter, as well as utilities for managing changes
    'lewis6991/gitsigns.nvim',
    opts = {
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
      signs_staged = {
        add = { text = '┃+' },
        change = { text = '┃~' },
        delete = { text = '┃_' },
        topdelete = { text = '┃‾' },
        changedelete = { text = '┃~' },
      },
      signs_staged_enable = true,
      on_attach = function(bufnr)
        local gitsigns = require('gitsigns')

        -- Navigation
        vim.keymap.set('n', ']c', function()
          if vim.wo.diff then
            vim.cmd.normal { ']c', bang = true }
          else
            gitsigns.nav_hunk('next')
          end
        end, { buffer = bufnr, desc = 'Jump to next git change' })

        vim.keymap.set('n', '[c', function()
          if vim.wo.diff then
            vim.cmd.normal { '[c', bang = true }
          else
            gitsigns.nav_hunk('prev')
          end
        end, { buffer = bufnr, desc = 'Jump to previous git change' })

        -- Actions
        vim.keymap.set('n', '<leader>gh', gitsigns.preview_hunk, { buffer = bufnr, desc = 'Git preview hunk' })
        vim.keymap.set('n', '<leader>gs', gitsigns.stage_hunk, { buffer = bufnr, desc = 'Git stage hunk' })
        vim.keymap.set('v', '<leader>gs', function()
          gitsigns.stage_hunk { vim.fn.line('.'), vim.fn.line('v') }
        end, { buffer = bufnr, desc = 'Git stage hunk' })
        vim.keymap.set('n', '<leader>gu', gitsigns.undo_stage_hunk, { buffer = bufnr, desc = 'Git unstage hunk' })
        vim.keymap.set('n', '<leader>gS', gitsigns.stage_buffer, { buffer = bufnr, desc = 'Git stage buffer' })
        vim.keymap.set('n', '<leader>gr', gitsigns.reset_hunk, { buffer = bufnr, desc = 'Git reset hunk' })
        vim.keymap.set('v', '<leader>gr', function()
          gitsigns.reset_hunk { vim.fn.line('.'), vim.fn.line('v') }
        end, { buffer = bufnr, desc = 'Git reset hunk' })
        vim.keymap.set('n', '<leader>gR', gitsigns.reset_buffer, { buffer = bufnr, desc = 'Git reset buffer' })
        vim.keymap.set('n', '<leader>gb', gitsigns.blame_line, { buffer = bufnr, desc = 'Git blame line' })
        vim.keymap.set('n', '<leader>gd', gitsigns.diffthis, { buffer = bufnr, desc = 'Git diff against index' })
        vim.keymap.set('n', '<leader>gD', function()
          gitsigns.diffthis('@')
        end, { buffer = bufnr, desc = 'Git diff against last commit' })

        -- Toggles
        vim.keymap.set('n', '<leader>tb', gitsigns.toggle_current_line_blame, { buffer = bufnr, desc = 'Toggle git blame line' })
        vim.keymap.set('n', '<leader>td', gitsigns.toggle_deleted, { buffer = bufnr, desc = 'Toggle git deleted' })
      end,
    },
  },
  {
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
    end,
  },
}

