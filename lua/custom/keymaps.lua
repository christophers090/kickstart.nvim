-- Set the leader keys for custom keybindings
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Make :Q quit all windows
vim.cmd('command! Q qa')

vim.keymap.set('n', '<leader>pv', vim.cmd.Ex)

vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Disable scroll wheel
vim.keymap.set('', '<ScrollWheelUp>', '<Nop>')
vim.keymap.set('', '<ScrollWheelDown>', '<Nop>')
vim.keymap.set('', '<ScrollWheelLeft>', '<Nop>')
vim.keymap.set('', '<ScrollWheelRight>', '<Nop>')

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })
vim.keymap.set('n', '<leader>z', ':ZenMode<CR>', { desc = 'Toggle ZenMode' })
vim.keymap.set('n', '<leader>tm', ':terminal <CR>', { desc = 'Open terminal' })
vim.keymap.set('n', '<leader>ca', ':CodeCompanion', { desc = 'Open a chat' })

-- Exit terminal mode with double Esc
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Open scratch buffer to build commands with vim motions
vim.keymap.set('n', '<leader>tc', function()
  -- Create a small split at bottom
  vim.cmd('split')
  vim.cmd('resize 5')
  -- Create scratch buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(buf)
  vim.bo.buftype = 'nofile'
  vim.bo.bufhidden = 'wipe'
  -- Add instruction
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { '# Build your command here, then <CR> to send to terminal' })
  vim.cmd('startinsert!')
  
  -- Map Enter to send line to terminal and close
  vim.keymap.set('n', '<CR>', function()
    local line = vim.api.nvim_get_current_line()
    if not line:match('^#') and line ~= '' then
      vim.cmd('close')
      -- Find terminal window and send command
      local term_win = vim.fn.win_findbuf(vim.fn.bufnr('#'))[1]
      if term_win then
        vim.api.nvim_win_call(term_win, function()
          vim.api.nvim_feedkeys('i' .. line .. '\n', 'n', false)
        end)
      end
    end
  end, { buffer = buf })
end, { desc = '[T]erminal [C]ommand builder' })

-- TIP: Disable arrow keys in normal mode
-- vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
-- vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
-- vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
-- vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })
vim.opt.splitbelow = true -- Horizontal splits open below
vim.opt.splitright = true -- Vertical splits open to the right
vim.keymap.set('n', '<leader>we', ':vsplit<CR>', { desc = 'Split vertically' })
vim.keymap.set('n', '<leader>wh', ':split<CR>', { desc = 'Split horizontally' })
vim.keymap.set('n', '<leader>wc', ':close<CR>', { desc = 'Close split' })
vim.keymap.set('n', '<leader>wo', ':only<CR>', { desc = 'Close other splits' })

-- C++ specific functions
local cpp = require 'custom.functions.cpp'
vim.keymap.set('n', '<leader>ui', cpp.toggle_header_impl, { desc = 'Toggle header/implementation' })

-- Bazel functions
local bazel = require 'custom.functions.bazel'
vim.keymap.set('n', '<leader>bg', bazel.refresh_compile_commands, { desc = '[B]azel [G]enerate compile_commands.json' })
vim.keymap.set('n', '<leader>uo', bazel.open_build_file, { desc = 'Open BUILD.bazel file' })

-- LSP
vim.keymap.set('n', '<leader>gd', vim.lsp.buf.definition, { desc = 'Go to deff' })
vim.keymap.set('n', '<leader>fj', function()
  require('conform').format({ async = true, lsp_format = 'fallback' })
end, { desc = 'Format buffer' })
vim.keymap.set('n', '<leader>ge', vim.lsp.buf.references, { desc = 'Show references' })
vim.keymap.set('n', '<leader>gi', vim.lsp.buf.implementation, { desc = 'Go to implementation' })
vim.keymap.set('n', '<leader>gh', vim.lsp.buf.hover, { desc = 'Hover documentation' })

-- Telescope
local new_file = require 'custom.functions.new_file'
vim.keymap.set('n', '<leader>fn', new_file.create_new_file, { desc = 'Create a new file' })

-- Quick file search: current dir only (sj) and with parent (sp)
vim.keymap.set('n', 'sj', function()
  local buf_dir = vim.fn.expand('%:p:h')
  require('telescope.builtin').find_files({
    search_dirs = { buf_dir },
  })
end, { desc = 'Search files in buffer dir (Telescope)' })

vim.keymap.set('n', 'sp', function()
  local buf_dir = vim.fn.expand('%:p:h')
  local parent_dir = vim.fn.fnamemodify(buf_dir, ':h')
  require('telescope.builtin').find_files({
    search_dirs = { buf_dir, parent_dir },
  })
end, { desc = 'Search files in buffer dir and parent (Telescope)' })
