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
vim.keymap.set('n', '<leader>ca', ':CodeCompanion', { desc = 'Open a chat' })

-- Exit terminal mode with double Esc
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Terminal-only: in terminal buffers, pressing Enter in NORMAL mode starts Visual mode
vim.api.nvim_create_autocmd('TermOpen', {
  callback = function(args)
    vim.keymap.set('n', '<CR>', 'v', { buffer = args.buf, desc = 'Terminal: Enter -> Visual' })
  end,
})

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
  bazel.build_current_file_in_terminal('build')
end, { desc = '[B]azel [B]uild current file target' })
vim.keymap.set('n', '<leader>br', function()
  bazel.build_current_file_in_terminal('run')
end, { desc = '[B]azel [R]un current file target (pasted only)' })
-- LSP
vim.keymap.set('n', '<leader>ch', vim.lsp.buf.hover, { desc = '[C]ode [H]over documentation' })
vim.keymap.set('n', '<leader>cf', function()
  require('conform').format({ async = true, lsp_format = 'fallback' })
end, { desc = '[C]ode [F]ormat buffer' })

-- Telescope
local new_file = require 'utils.new_file'
vim.keymap.set('n', '<leader>fn', new_file.create_new_file, { desc = 'Create a new file' })

-- Custom grep with glob pattern support
local telescope_grep = require 'utils.telescope_grep'
local telescope_files = require 'utils.telescope_files'
vim.keymap.set('n', '<leader>sl', function()
  local current_dir = vim.fn.expand('%:p:h')
  telescope_grep.live_grep_with_glob_in_dir(current_dir)
end, { desc = '[S]earch by grep with glob in current dir ([L]ocal)' })

-- Quick grep with pre-filled globs
vim.keymap.set('n', '<leader>sj', function()
  telescope_grep.regex_live_grep_with_glob('*.*')
end, { desc = 'Regex grep with all files glob' })

vim.keymap.set('n', '<leader>sk', function()
  local current_dir = vim.fn.expand('%:p:h')
  local dir_name = vim.fn.fnamemodify(current_dir, ':t')
  local glob = dir_name ~= '' and ('**/' .. dir_name .. '/*.*') or '**/*.*'
  telescope_grep.regex_live_grep_with_glob(glob)
end, { desc = 'Regex grep in current directory (recursive)' })

vim.keymap.set('n', '<leader>su', function()
  local current_dir = vim.fn.expand('%:p:h')
  local parent_dir = vim.fn.fnamemodify(current_dir, ':h')
  local parent_name = vim.fn.fnamemodify(parent_dir, ':t')
  local glob = parent_name ~= '' and ('**/' .. parent_name .. '/*.*') or '**/*.*'
  telescope_grep.regex_live_grep_with_glob(glob)
end, { desc = 'Regex grep in parent directory' })

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
  telescope_grep.regex_live_grep_with_glob('*.*', term)
end, { desc = 'Regex grep term (word/visual) in all files' })

vim.keymap.set({ 'n', 'x' }, '<leader>sak', function()
  local term = get_term_from_mode()
  local current_dir = vim.fn.expand('%:p:h')
  local dir_name = vim.fn.fnamemodify(current_dir, ':t')
  local glob = dir_name ~= '' and ('**/' .. dir_name .. '/*.*') or '**/*.*'
  telescope_grep.regex_live_grep_with_glob(glob, term)
end, { desc = 'Regex grep term (word/visual) in current dir (recursive)' })

vim.keymap.set({ 'n', 'x' }, '<leader>sau', function()
  local term = get_term_from_mode()
  local current_dir = vim.fn.expand('%:p:h')
  local parent_dir = vim.fn.fnamemodify(current_dir, ':h')
  local parent_name = vim.fn.fnamemodify(parent_dir, ':t')
  local glob = parent_name ~= '' and ('**/' .. parent_name .. '/*.*') or '**/*.*'
  telescope_grep.regex_live_grep_with_glob(glob, term)
end, { desc = 'Regex grep term (word/visual) in parent dir' })

-- File search with captured term (glob-aware)
vim.keymap.set({ 'n', 'x' }, '<leader>saf', function()
  local term = get_term_from_mode()
  telescope_files.find_files_with_glob('*.*', term, nil)
end, { desc = 'Find files (word/visual) in all dirs' })

vim.keymap.set({ 'n', 'x' }, '<leader>sad', function()
  local term = get_term_from_mode()
  local current_dir = vim.fn.expand('%:p:h')
  local dir_name = vim.fn.fnamemodify(current_dir, ':t')
  local glob = dir_name ~= '' and ('**/' .. dir_name .. '/*.*') or '**/*.*'
  telescope_files.find_files_with_glob(glob, term, nil)
end, { desc = 'Find files (word/visual) using current dir glob' })

vim.keymap.set({ 'n', 'x' }, '<leader>sar', function()
  local term = get_term_from_mode()
  local current_dir = vim.fn.expand('%:p:h')
  local parent_dir = vim.fn.fnamemodify(current_dir, ':h')
  local parent_name = vim.fn.fnamemodify(parent_dir, ':t')
  local glob = parent_name ~= '' and ('**/' .. parent_name .. '/*.*') or '**/*.*'
  telescope_files.find_files_with_glob(glob, term, nil)
end, { desc = 'Find files (word/visual) using parent dir glob' })

-- Fuzzy file search (sl variants)
local function find_files_with_default(cwd, term)
  local builtin = require('telescope.builtin')
  builtin.find_files({ cwd = cwd, default_text = term, hidden = true })
end

vim.keymap.set('n', '<leader>slj', function()
  find_files_with_default(nil, nil)
end, { desc = 'Fuzzy files (workspace)' })

vim.keymap.set('n', '<leader>slk', function()
  local current_dir = vim.fn.expand('%:p:h')
  find_files_with_default(current_dir, nil)
end, { desc = 'Fuzzy files (current dir)' })

vim.keymap.set('n', '<leader>slu', function()
  local current_dir = vim.fn.expand('%:p:h')
  local parent_dir = vim.fn.fnamemodify(current_dir, ':h')
  find_files_with_default(parent_dir, nil)
end, { desc = 'Fuzzy files (parent dir)' })

-- Add word/visual term to fuzzy filename search
vim.keymap.set({ 'n', 'x' }, '<leader>slaj', function()
  local term = get_term_from_mode()
  find_files_with_default(nil, term)
end, { desc = 'Fuzzy files with term (workspace)' })

vim.keymap.set({ 'n', 'x' }, '<leader>slak', function()
  local term = get_term_from_mode()
  local current_dir = vim.fn.expand('%:p:h')
  find_files_with_default(current_dir, term)
end, { desc = 'Fuzzy files with term (current dir)' })

vim.keymap.set({ 'n', 'x' }, '<leader>slau', function()
  local term = get_term_from_mode()
  local current_dir = vim.fn.expand('%:p:h')
  local parent_dir = vim.fn.fnamemodify(current_dir, ':h')
  find_files_with_default(parent_dir, term)
end, { desc = 'Fuzzy files with term (parent dir)' })

-- Helpers: repository root detection and relative path construction
local function get_repo_root(start_dir)
  -- Prefer git worktree/toplevel; robust with worktrees
  local out = vim.fn.systemlist({ 'git', '-C', start_dir, 'rev-parse', '--show-toplevel' })
  if vim.v.shell_error == 0 and out and out[1] and out[1] ~= '' then
    return out[1]
  end
  -- Fallback to Bazel WORKSPACE if present
  local ws = vim.fn.findfile('WORKSPACE', start_dir .. ';')
  if ws ~= '' then
    return vim.fn.fnamemodify(ws, ':h')
  end
  -- Fallback to current working directory
  return vim.fn.getcwd()
end

local function to_relative(path, root)
  if not path or not root then return path end
  -- Normalize trailing slash handling
  if path:sub(1, #root) == root then
    local offset = #root
    if path:sub(offset + 1, offset + 1) == '/' then
      offset = offset + 1
    end
    return path:sub(offset + 0)
  end
  -- Last resort: make relative to current cwd
  return vim.fn.fnamemodify(path, ':.')
end

-- Spectre keymaps
vim.keymap.set('n', '<leader>ir', function()
  local current_dir = vim.fn.expand('%:p:h')
  local parent_dir = vim.fn.fnamemodify(current_dir, ':h')
  local search_dir = (parent_dir ~= current_dir and parent_dir ~= '/') and parent_dir or current_dir
  local repo_root = get_repo_root(current_dir)
  local rel = to_relative(search_dir, repo_root)
  local path_glob = (rel ~= '' and ('**/' .. rel .. '/*.*')) or '**/*.*'
  require('spectre').open_visual({
    select_word = true,
    cwd = repo_root,
    path = path_glob,
  })
end, { desc = 'Replace word in dir and parent' })

vim.keymap.set('n', '<leader>id', function()
  local current_dir = vim.fn.expand('%:p:h')
  local repo_root = get_repo_root(current_dir)
  local rel = to_relative(current_dir, repo_root)
  local path_glob = (rel ~= '' and ('**/' .. rel .. '/*.*')) or '**/*.*'
  require('spectre').open_visual({
    select_word = true,
    cwd = repo_root,
    path = path_glob,
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

