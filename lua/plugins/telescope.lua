return {
  { -- Fuzzy Finder (files, lsp, etc)
    'nvim-telescope/telescope.nvim',
    event = 'VimEnter',
    dependencies = {
      'nvim-lua/plenary.nvim',
      { -- If encountering errors, see telescope-fzf-native README for installation instructions
        'nvim-telescope/telescope-fzf-native.nvim',

        -- `build` is used to run some command when the plugin is installed/updated.
        -- This is only run then, not every time Neovim starts up.
        build = 'make',

        -- `cond` is a condition used to determine whether this plugin should be
        -- installed and loaded.
        cond = function()
          return vim.fn.executable 'make' == 1
        end,
      },
      { 'nvim-telescope/telescope-ui-select.nvim' },

      -- Useful for getting pretty icons, but requires a Nerd Font.
      { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
    },
    config = function()
      -- Telescope is a fuzzy finder that comes with a lot of different things that
      -- it can fuzzy find! It's more than just a "file finder", it can search
      -- many different aspects of Neovim, your workspace, LSP, and more!
      --
      -- The easiest way to use Telescope, is to start by doing something like:
      --  :Telescope help_tags
      --
      -- After running this command, a window will open up and you're able to
      -- type in the prompt window. You'll see a list of `help_tags` options and
      -- a corresponding preview of the help.
      --
      -- Two important keymaps to use while in Telescope are:
      --  - Insert mode: <c-/>
      --  - Normal mode: ?
      --
      -- This opens a window that shows you all of the keymaps for the current
      -- Telescope picker. This is really useful to discover what Telescope can
      -- do as well as how to actually do it!

      -- [[ Configure Telescope ]]
      -- See `:help telescope` and `:help telescope.setup()`
      require('telescope').setup { -- You can put your default mappings / updates / etc. in here
        --  All the info you're looking for is in `:help telescope.setup()`
        --
        -- defaults = {
        --   hidden = true,
        -- },
        pickers = {
          find_files = {
            hidden = true,
            file_ignore_patterns = { '^.git/', '.cache/' },
          },
        },
        extensions = {
          ['ui-select'] = {
            require('telescope.themes').get_dropdown(),
          },
        },
      }

      -- Enable Telescope extensions if they are installed
      pcall(require('telescope').load_extension, 'fzf')
      pcall(require('telescope').load_extension, 'ui-select')

      -- See `:help telescope.builtin`
      local builtin = require 'telescope.builtin'
      local search = require 'utils.search'
      local perl = require 'utils.perl'
      
      -- File search
      vim.keymap.set('n', '<leader>sf', function()
        search.find_files({ glob = '*.*' })
      end, { desc = '[S]earch [F]iles (glob aware: term  glob or just glob)' })
      vim.keymap.set('n', '<leader>sd', function()
        search.find_files({ scope = 'current' })
      end, { desc = '[S]earch files in current [D]irectory (prefill recursive glob)' })
      vim.keymap.set('n', '<leader>sr', function()
        search.find_files({ scope = 'parent' })
      end, { desc = '[S]earch files in pa[R]ent (prefill recursive glob)' })
      
      -- Grep search (custom bindings defined in lua/config/keymaps.lua)
      vim.keymap.set('n', '<leader>so', function()
        require('telescope.builtin').find_files {
          prompt_title = 'Select Directory',
          find_command = { 'find', '.', '-type', 'd', '-not', '-path', '*/.git/*', '-not', '-path', '*/bazel-*' },
          attach_mappings = function(prompt_bufnr, map)
            local actions = require 'telescope.actions'
            local action_state = require 'telescope.actions.state'

            actions.select_default:replace(function()
              local selection = action_state.get_selected_entry()
              actions.close(prompt_bufnr)
              if selection then
                require('telescope.builtin').live_grep { cwd = selection.value }
              end
            end)
            return true
          end,
        }
      end, { desc = '[S]earch by grep in selected direct[O]ry' })
      
      -- Other searches
      vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
      vim.keymap.set('n', '<leader>sD', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
      vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
      vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files' })
      vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

      -- Slightly advanced example of overriding default behavior and theme
      vim.keymap.set('n', '<leader>/', function()
        -- You can pass additional configuration to Telescope to change the theme, layout, etc.
        builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
          winblend = 10,
          previewer = false,
        })
      end, { desc = '[/] Fuzzily search in current buffer' })

      -- It's also possible to pass additional configuration options.
      --  See `:help telescope.builtin.live_grep()` for information about particular keys
      vim.keymap.set('n', '<leader>s/', function()
        builtin.live_grep {
          grep_open_files = true,
          prompt_title = 'Live Grep in Open Files',
        }
      end, { desc = '[S]earch [/] in Open Files' })


      -- Interactive perl regex with live preview
      vim.keymap.set({ 'n', 'x' }, '<leader>is', perl.run, { desc = '[I]nteractive [S]ubstitute (perl regex)' })
    end,
  },
}
