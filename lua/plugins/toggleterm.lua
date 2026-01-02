return {
  {
    'akinsho/toggleterm.nvim',
    version = "*",
    config = function()
      require("toggleterm").setup({
        size = 20,
        open_mapping = [[<c-\>]],
        hide_numbers = true,
        shade_filetypes = {},
        shade_terminals = true,
        shading_factor = 2,
        start_in_insert = true,
        insert_mappings = true,
        persist_size = true,
        direction = "float",
        close_on_exit = true,
        shell = vim.o.shell,
        float_opts = {
          border = "curved",
          width = function() return math.ceil(vim.o.columns * 0.6) end,
          height = function() return math.ceil(vim.o.lines * 0.6) end,
          winblend = 0,
          highlights = {
            border = "Normal",
            background = "Normal",
          },
        },
      })

      function _G.set_terminal_keymaps()
        local opts = {buffer = 0}
        vim.keymap.set('t', '<Esc><Esc>', [[<cmd>ToggleTerm<CR>]], opts)
        vim.keymap.set('t', 'jk', [[<C-\><C-n>]], opts)
        vim.keymap.set('t', '<C-h>', [[<Cmd>wincmd h<CR>]], opts)
        vim.keymap.set('t', '<C-j>', [[<Cmd>wincmd j<CR>]], opts)
        vim.keymap.set('t', '<C-k>', [[<Cmd>wincmd k<CR>]], opts)
        vim.keymap.set('t', '<C-l>', [[<Cmd>wincmd l<CR>]], opts)
        vim.keymap.set('t', '<C-w>', [[<C-\><C-n><C-w>]], opts)
      end

      -- if you only want these mappings for toggle term use term://*toggleterm#* instead
      vim.cmd('autocmd! TermOpen term://*toggleterm#* lua set_terminal_keymaps()')
      
      -- Custom keymap to toggle terminal
      -- Pin this to a dedicated "generic" terminal (ID 1) so it stays separate
      -- from the Claude Code terminal below.
      vim.keymap.set('n', '<leader>tk', '<cmd>1ToggleTerm direction=float<cr>', { desc = 'Toggle floating terminal' })

      -- Dedicated Claude Code terminal (persistent)
      local Terminal = require('toggleterm.terminal').Terminal
      local function most_recent_file_buf()
        local infos = vim.fn.getbufinfo({ buflisted = 1 })
        table.sort(infos, function(a, b)
          return (a.lastused or 0) > (b.lastused or 0)
        end)
        for _, info in ipairs(infos) do
          local buf = info.bufnr
          if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == '' then
            local name = vim.api.nvim_buf_get_name(buf)
            if name ~= '' and not name:match('^term://') then
              return buf
            end
          end
        end
        return nil
      end

      local function bazel_from_recent_file(mode)
        local ok, bazel = pcall(require, 'utils.bazel')
        if not ok then
          vim.notify('utils.bazel not available', vim.log.levels.ERROR)
          return
        end
        local buf = most_recent_file_buf()
        if not buf then
          vim.notify('No file buffer found for Bazel build/run', vim.log.levels.WARN)
          return
        end
        vim.api.nvim_buf_call(buf, function()
          bazel.build_current_file_in_terminal(mode, true)
        end)
      end

      local claude_term = Terminal:new({
        id = 99,
        cmd = 'claude --dangerously-skip-permissions',
        direction = 'float',
        display_name = 'Claude Code',
        on_create = function(term)
          -- Keep buffer/job alive when window is closed
          vim.bo[term.bufnr].bufhidden = 'hide'

          -- Claude panel key behavior:
          -- - <Esc>: leave terminal mode (so you can scroll)
          -- - <Esc><Esc>: hide the float (keep process running)
          --
          -- We implement the double-esc close by mapping <Esc> in terminal mode
          -- and mapping <Esc> in normal mode to close the window. We also delete
          -- the default ToggleTerm <Esc><Esc> mapping for this buffer to avoid
          -- single-esc being delayed by `timeoutlen`.
          vim.keymap.set('t', '<Esc>', [[<C-\><C-n>]], { buffer = term.bufnr, nowait = true })
          pcall(vim.keymap.del, 't', '<Esc><Esc>', { buffer = term.bufnr })
          vim.keymap.set('n', '<Esc>', function()
            term:close()
          end, { buffer = term.bufnr, desc = 'Hide Claude Code terminal' })

          -- Keep Bazel leader actions working even when the Claude terminal has focus.
          -- This prevents `<leader>bb` / `<leader>br` being sent as input to Claude.
          vim.keymap.set('t', '<leader>bb', function()
            bazel_from_recent_file('build')
          end, { buffer = term.bufnr, desc = '[B]azel [B]uild (from recent file)' })
          vim.keymap.set('t', '<leader>br', function()
            bazel_from_recent_file('run')
          end, { buffer = term.bufnr, desc = '[B]azel [R]un (from recent file)' })
        end,
      })

      vim.keymap.set('n', '<leader>cl', function()
        claude_term:toggle()
      end, { desc = 'Toggle Claude Code (float)' })

      -- Pre-warm Claude in the background (no window) so opening the panel is fast.
      if vim.fn.executable('claude') == 1 then
        vim.schedule(function()
          if not claude_term.job_id then
            claude_term:spawn()
          end
        end)
      end
    end
  }
}

