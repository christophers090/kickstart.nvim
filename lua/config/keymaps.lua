-- Set the leader keys for custom keybindings
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Make :Q quit all windows
vim.cmd('command! Q qa')

-- Make :W and :w save files, :WQ/:Wq variations
vim.cmd('command! W w')
vim.cmd('command! WQ wqa')
vim.cmd('command! Wq wq')

-- Make :G run git commands
vim.cmd('command! -nargs=+ G !git <args>')

-- [Removed] <leader>pv file explorer mapping

vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')
-- Ensure % behaves like $ (end of line) across modes and after plugins load
vim.api.nvim_create_autocmd('User', {
  pattern = 'VeryLazy',
  callback = function()
    vim.keymap.set({ 'n', 'x', 'o' }, '%', function()
      return (vim.v.count > 0 and tostring(vim.v.count) or '') .. '$'
    end, { expr = true, desc = 'End of line' })
  end,
})

-- Reverse { and } for paragraph/block movement (Forcefully applied)
local function set_block_movement()
  vim.keymap.set({ 'n', 'x', 'o' }, '}', '{', { desc = 'Move up a block', silent = true })
  vim.keymap.set({ 'n', 'x', 'o' }, '{', '}', { desc = 'Move down a block', silent = true })
end

set_block_movement()

vim.api.nvim_create_autocmd('VimEnter', {
  callback = set_block_movement,
})

-- Disable scroll wheel
vim.keymap.set('', '<ScrollWheelUp>', '<Nop>')
vim.keymap.set('', '<ScrollWheelDown>', '<Nop>')
vim.keymap.set('', '<ScrollWheelLeft>', '<Nop>')
vim.keymap.set('', '<ScrollWheelRight>', '<Nop>')

-- Paste behavior: default p/P keep register in Visual mode; <leader>p does replace
-- In Visual mode, paste without overwriting the unnamed register (restore selection)
vim.keymap.set('x', 'p', 'pgvy', { desc = 'Paste (keep register)' })
vim.keymap.set('x', 'P', 'Pgvy', { desc = 'Paste before (keep register)' })
-- In Visual mode, <leader>p uses the original behavior (paste and replace register)
vim.keymap.set('x', '<leader>p', function()
  vim.cmd('normal! p')
end, { desc = 'Paste (replace register)' })

-- Path copy helpers
local function copy_to_registers(text, label)
  if not text or text == '' then
    vim.notify('No path to copy', vim.log.levels.WARN)
    return
  end
  vim.fn.setreg('"', text)
  pcall(vim.fn.setreg, '+', text)
  vim.notify(label .. ': ' .. text)
end

vim.keymap.set('n', 'yd', function()
  local dir = vim.fn.expand('%:p:h')
  if dir == '' then
    vim.notify('No directory for current buffer', vim.log.levels.WARN)
    return
  end
  local rel = vim.fn.fnamemodify(dir, ':~')
  copy_to_registers(rel, 'Copied directory')
end, { desc = 'Yank current file directory (~)' })

vim.keymap.set('n', 'ya', function()
  local file = vim.fn.expand('%:p')
  if file == '' then
    vim.notify('No file path for current buffer', vim.log.levels.WARN)
    return
  end
  local rel = vim.fn.fnamemodify(file, ':~')
  copy_to_registers(rel, 'Copied file path')
end, { desc = 'Yank absolute file path (~)' })

vim.keymap.set('n', '<leader>wt', function()
  local current_theme = vim.g.colors_name or 'default'
  vim.notify('Current theme: ' .. current_theme, vim.log.levels.INFO)
end, { desc = 'Show [W]hat [T]heme is active' })

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })
vim.keymap.set('n', '<leader>z', ':ZenMode<CR>', { desc = 'Toggle ZenMode' })
vim.keymap.set('n', '<leader>tm', ':terminal<CR>', { desc = 'Open terminal' })
vim.keymap.set('n', '<leader>te', ':vsplit | terminal<CR>', { desc = 'Open terminal in vertical split' })
vim.keymap.set('n', '<leader>th', ':split | terminal<CR>', { desc = 'Open terminal in horizontal split' })

-- Exit terminal mode with double Esc
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Terminal-only: in terminal buffers, pressing Enter in NORMAL mode starts Visual mode
vim.api.nvim_create_autocmd('TermOpen', {
  callback = function(args)
    vim.keymap.set('n', '<CR>', 'v', { buffer = args.buf, desc = 'Terminal: Enter -> Visual' })
  end,
})


-- TIP: Disable arrow keys in normal mode
vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

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

-- Move to middle of line
vim.keymap.set('n', 'm', function()
  local line = vim.api.nvim_get_current_line()
  if line == "" then return end
  local start_col = line:find("%S") or 1
  local end_col = #line
  local middle_col = math.floor((start_col + end_col) / 2)
  vim.api.nvim_win_set_cursor(0, { vim.fn.line('.'), middle_col - 1 })
end, { desc = 'Go to middle of code on line' })

local cpp = require 'utils.cpp'
vim.keymap.set('n', '<leader>ui', cpp.open_header_from_context, { desc = 'Open header/impl based on context' })
vim.keymap.set('n', '<leader>uc', cpp.open_cpp_from_context, { desc = 'Open C++ implementation from context' })
vim.keymap.set('n', '<leader>ud', cpp.open_idl_from_context, { desc = 'Open *_idl.* from context' })
vim.keymap.set('n', '<leader>ub', cpp.open_bazel_from_context, { desc = 'Open BUILD(.bazel) from context' })

-- Bazel functions
local bazel = require 'utils.bazel'
vim.keymap.set('n', '<leader>bg', bazel.refresh_compile_commands, { desc = '[B]azel [G]enerate compile_commands.json' })
vim.keymap.set('n', '<leader>uf', bazel.open_build_file, { desc = 'Open BUILD.bazel file' })
vim.keymap.set('n', '<leader>bb', function()
  bazel.build_current_file_in_terminal('build', true)
end, { desc = '[B]azel [B]uild current file target (float)' })
vim.keymap.set('n', '<leader>br', function()
  bazel.build_current_file_in_terminal('run', true)
end, { desc = '[B]azel [R]un current file target (float)' })
vim.keymap.set('n', '<leader>blb', function()
  bazel.build_current_file_in_terminal('build', false)
end, { desc = '[B]azel [L]ine [B]uild current file target (split)' })
vim.keymap.set('n', '<leader>blr', function()
  bazel.build_current_file_in_terminal('run', false)
end, { desc = '[B]azel [L]ine [R]un current file target (split)' })
-- LSP
vim.keymap.set('n', '<leader>ch', vim.lsp.buf.hover, { desc = '[C]ode [H]over documentation' })
vim.keymap.set('n', '<leader>cf', function()
  require('conform').format({ async = true, lsp_format = 'fallback' })
end, { desc = '[C]ode [F]ormat buffer' })

-- Unified search module
local search = require 'utils.search'

vim.keymap.set('n', '<leader>sl', function()
  search.grep({ scope = 'current' })
end, { desc = '[S]earch by grep in current dir ([L]ocal)' })

-- Quick grep with pre-filled globs
vim.keymap.set('n', '<leader>sj', function()
  search.grep({ glob = '*.*' })
end, { desc = 'Grep with all files glob' })

vim.keymap.set('n', '<leader>sk', function()
  search.grep({ scope = 'current' })
end, { desc = 'Grep in current directory (recursive)' })

vim.keymap.set('n', '<leader>su', function()
  search.grep({ scope = 'parent' })
end, { desc = 'Grep in parent directory' })

-- Utilities to capture search term
local function get_visual_selection_text()
  local s = vim.fn.getpos("'<")
  local e = vim.fn.getpos("'>")
  local lines = vim.fn.getline(s[2], e[2])
  if #lines == 0 then return '' end
  lines[1] = string.sub(lines[1], s[3])
  lines[#lines] = string.sub(lines[#lines], 1, e[3])
  return table.concat(lines, ' ')
end

local function get_term_from_mode()
  if vim.fn.mode():match('^[vV\022]') then
    local txt = get_visual_selection_text()
    if txt ~= '' then return txt end
  end
  return vim.fn.expand('<cword>')
end

-- Prefill with word under cursor or visual selection
vim.keymap.set({ 'n', 'x' }, '<leader>saj', function()
  local term = get_term_from_mode()
  search.grep({ glob = '*.*', term = term })
end, { desc = 'Grep term (word/visual) in all files' })

vim.keymap.set({ 'n', 'x' }, '<leader>sak', function()
  local term = get_term_from_mode()
  search.grep({ scope = 'current', term = term })
end, { desc = 'Grep term (word/visual) in current dir (recursive)' })

vim.keymap.set({ 'n', 'x' }, '<leader>sau', function()
  local term = get_term_from_mode()
  search.grep({ scope = 'parent', term = term })
end, { desc = 'Grep term (word/visual) in parent dir' })

-- File search with captured term (glob-aware)
vim.keymap.set({ 'n', 'x' }, '<leader>saf', function()
  local term = get_term_from_mode()
  search.find_files({ glob = '*.*', term = term })
end, { desc = 'Find files (word/visual) in all dirs' })

vim.keymap.set({ 'n', 'x' }, '<leader>sad', function()
  local term = get_term_from_mode()
  search.find_files({ scope = 'current', term = term })
end, { desc = 'Find files (word/visual) in current dir' })

vim.keymap.set({ 'n', 'x' }, '<leader>sar', function()
  local term = get_term_from_mode()
  search.find_files({ scope = 'parent', term = term })
end, { desc = 'Find files (word/visual) in parent dir' })

-- Fuzzy file search (sl variants) - using Telescope builtin for simple fuzzy
vim.keymap.set('n', '<leader>slj', function()
  require('telescope.builtin').find_files({ hidden = true })
end, { desc = 'Fuzzy files (workspace)' })

vim.keymap.set('n', '<leader>slk', function()
  require('telescope.builtin').find_files({ cwd = search.get_current_dir(), hidden = true })
end, { desc = 'Fuzzy files (current dir)' })

vim.keymap.set('n', '<leader>slu', function()
  require('telescope.builtin').find_files({ cwd = search.get_parent_dir(), hidden = true })
end, { desc = 'Fuzzy files (parent dir)' })

-- Add word/visual term to fuzzy filename search
vim.keymap.set({ 'n', 'x' }, '<leader>slaj', function()
  local term = get_term_from_mode()
  require('telescope.builtin').find_files({ default_text = term, hidden = true })
end, { desc = 'Fuzzy files with term (workspace)' })

vim.keymap.set({ 'n', 'x' }, '<leader>slak', function()
  local term = get_term_from_mode()
  require('telescope.builtin').find_files({ cwd = search.get_current_dir(), default_text = term, hidden = true })
end, { desc = 'Fuzzy files with term (current dir)' })

vim.keymap.set({ 'n', 'x' }, '<leader>slau', function()
  local term = get_term_from_mode()
  require('telescope.builtin').find_files({ cwd = search.get_parent_dir(), default_text = term, hidden = true })
end, { desc = 'Fuzzy files with term (parent dir)' })

-- Bazel-bin search
vim.keymap.set('n', '<leader>sb', function()
  local repo_root = search.get_repo_root(vim.fn.getcwd())
  local bazel_bin = repo_root .. '/bazel-bin'
  search.find_files({ cwd = bazel_bin, glob = '*.*', title = 'Find Files (bazel-bin)' })
end, { desc = '[S]earch files in [B]azel-bin' })

vim.keymap.set('n', '<leader>sn', function()
  local repo_root = search.get_repo_root(vim.fn.getcwd())
  local bazel_bin = repo_root .. '/bazel-bin'
  search.grep({ cwd = bazel_bin, glob = '*.*', title = 'Grep (bazel-bin)' })
end, { desc = '[S]earch (grep) in bazel-bi[N]' })

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

