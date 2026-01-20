-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

local function set_terminal_window_opts(buf)
  -- Buffer-local (safe even when the terminal is spawned without a window)
  pcall(function()
    vim.bo[buf].scrollback = 5000
  end)

  -- Window-local (apply to every window currently displaying the buffer)
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    vim.wo[win].number = false
    vim.wo[win].relativenumber = false
    vim.wo[win].signcolumn = 'no'
    vim.wo[win].cursorline = false
    vim.wo[win].list = false
    vim.wo[win].spell = false
    vim.wo[win].foldcolumn = '0'
    vim.wo[win].colorcolumn = ''
  end
end

-- Terminal performance: keep terminal windows cheap to redraw
vim.api.nvim_create_autocmd({ 'TermOpen', 'BufWinEnter' }, {
  desc = 'Terminal: set fast window-local options',
  group = vim.api.nvim_create_augroup('terminal-performance', { clear = true }),
  pattern = { 'term://*' },
  callback = function(args)
    if vim.bo[args.buf].buftype ~= 'terminal' then
      return
    end
    set_terminal_window_opts(args.buf)
  end,
})

-- Force relative line numbers everywhere (except terminals/floats)
vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWinEnter', 'WinEnter' }, {
  desc = 'Enable relative line numbers everywhere',
  group = vim.api.nvim_create_augroup('force-relative-numbers', { clear = true }),
  callback = function()
    local buf = vim.api.nvim_get_current_buf()
    if vim.bo[buf].buftype == 'terminal' then
      return
    end
    local win = vim.api.nvim_get_current_win()
    if vim.api.nvim_win_get_config(win).relative ~= '' then
      return
    end
    vim.wo.number = true
    vim.wo.relativenumber = true
  end,
})

-- Automatically enter insert mode when focusing a terminal buffer or opening one
vim.api.nvim_create_autocmd({ 'BufEnter', 'TermOpen' }, {
  pattern = { 'term://*' },
  callback = function(args)
    -- Avoid forcing insert mode when a terminal is spawned in the background
    -- (e.g. ToggleTerm's `Terminal:spawn()` used for pre-warming).
    if vim.bo[args.buf].buftype ~= 'terminal' then
      return
    end

    -- Only enter insert mode if the terminal buffer is actually displayed in a
    -- window (background-spawned terminals have no windows).
    if vim.api.nvim_get_current_buf() ~= args.buf then
      return
    end
    if #vim.fn.win_findbuf(args.buf) == 0 then
      return
    end

    -- Defer to let buffer switching complete, then re-verify we're still in the terminal
    vim.schedule(function()
      local current_buf = vim.api.nvim_get_current_buf()
      local current_ft = vim.bo[current_buf].filetype
      -- Don't enter insert if we've switched away or we're on dashboard/special buffers
      if current_buf ~= args.buf or current_ft == 'alpha' then
        return
      end
      vim.cmd('startinsert')
    end)
  end,
})

-- Detect Bazel files by filename
vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
  pattern = { 'BUILD', 'BUILD.bazel', 'WORKSPACE', 'WORKSPACE.bazel', '*.bzl' },
  callback = function()
    vim.bo.filetype = 'starlark'
  end,
})


