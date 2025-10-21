-- Set the leader keys for custom keybindings
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Make :Q quit all windows
vim.cmd('command! Q qa')

-- Make :G run git commands
vim.cmd('command! -nargs=+ G !git <args>')

vim.keymap.set('n', '<leader>pv', vim.cmd.Ex)

vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Reverse { and } for paragraph/block movement
vim.keymap.set('n', '}', '{', { desc = 'Move up a block' })
vim.keymap.set('n', '{', '}', { desc = 'Move down a block' })
vim.keymap.set('v', '}', '{', { desc = 'Move up a block' })
vim.keymap.set('v', '{', '}', { desc = 'Move down a block' })

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

-- Disable hjkl unless preceded by a count
vim.keymap.set('n', 'h', function()
  if vim.v.count == 0 then
    return ''
  else
    return 'h'
  end
end, { expr = true, desc = 'Left (only with count)' })

vim.keymap.set('n', 'j', function()
  if vim.v.count == 0 then
    return ''
  else
    return 'j'
  end
end, { expr = true, desc = 'Down (only with count)' })

vim.keymap.set('n', 'k', function()
  if vim.v.count == 0 then
    return ''
  else
    return 'k'
  end
end, { expr = true, desc = 'Up (only with count)' })

vim.keymap.set('n', 'l', function()
  if vim.v.count == 0 then
    return ''
  else
    return 'l'
  end
end, { expr = true, desc = 'Right (only with count)' })

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
vim.keymap.set('n', '<leader>ch', vim.lsp.buf.hover, { desc = '[C]ode [H]over documentation' })
vim.keymap.set('n', '<leader>cf', function()
  require('conform').format({ async = true, lsp_format = 'fallback' })
end, { desc = '[C]ode [F]ormat buffer' })

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

-- Spectre keymaps
vim.keymap.set('n', '<leader>ir', function()
  local current_dir = vim.fn.expand('%:p:h')
  local parent_dir = vim.fn.fnamemodify(current_dir, ':h')
  local search_dir = current_dir
  if parent_dir ~= current_dir and parent_dir ~= '/' then
    search_dir = parent_dir
  end
  require('spectre').open_visual({
    select_word = true,
    path = search_dir .. '/**/*.*'
  })
end, { desc = 'Replace word in dir and parent' })

vim.keymap.set('n', '<leader>id', function()
  local current_dir = vim.fn.expand('%:p:h')
  require('spectre').open_visual({
    select_word = true,
    path = current_dir .. '/**/*.*'
  })
end, { desc = 'Replace word in current directory' })

vim.keymap.set('n', '<leader>if', function()
  require('spectre').open_visual({ select_word = true })
end, { desc = 'Replace word (global)' })

vim.keymap.set('n', '<leader>iw', function()
  require('spectre').open_file_search({ select_word = true })
end, { desc = 'Replace word in current file' })

vim.keymap.set('n', '<leader>in', function()
  require('spectre').open()
end, { desc = 'Open spectre (no word)' })

-- Gitsigns keymaps (loaded after gitsigns loads)
vim.api.nvim_create_autocmd('User', {
  pattern = 'GitSignsAttach',
  callback = function(args)
    local gitsigns = require('gitsigns')
    local bufnr = args.buf
    
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
})

-- Neogit keymaps
vim.keymap.set('n', '<leader>ga', '<cmd>Neogit<cr>', { desc = 'Open Neogit' })
vim.keymap.set('n', '<leader>gc', '<cmd>Neogit commit<cr>', { desc = 'Neogit commit' })
vim.keymap.set('n', '<leader>gp', '<cmd>Neogit pull<cr>', { desc = 'Neogit pull' })
vim.keymap.set('n', '<leader>gP', '<cmd>Neogit push<cr>', { desc = 'Neogit push' })
vim.keymap.set('n', '<leader>gi', function()
  vim.ui.input({ prompt = 'Rebase onto: ', default = 'HEAD~10' }, function(input)
    if input and input ~= '' then
      vim.cmd('G rebase -i ' .. input)
    end
  end)
end, { desc = 'Interactive rebase' })
