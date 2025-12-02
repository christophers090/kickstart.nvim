local M = {}
local search = require('utils.search')

local function fallback_to_sr_with_ext(ext_to_find)
  local current_dir = vim.fn.expand('%:p:h')
  search.find_files_by_ext(ext_to_find, current_dir)
end

function M.refresh_compile_commands()
  -- Check if we're in a Bazel project
  local workspace_file = vim.fn.findfile('WORKSPACE', '.;')
  if workspace_file == '' then
    print('Not in a Bazel project (no WORKSPACE file found)')
    return
  end
  
  -- Run the hedron compile commands refresh
  print('Refreshing compile_commands.json...')
  vim.fn.jobstart('bazel run @hedron_compile_commands//:refresh_all', {
    on_exit = function(_, exit_code)
      if exit_code == 0 then
        print('compile_commands.json refreshed successfully')
        -- Restart clangd to pick up the new compile commands
        vim.cmd('LspRestart clangd')
        -- Also clear the clangd cache
        vim.fn.system('rm -rf ~/.cache/clangd')
        print('Cleared clangd cache')
      else
        print('Failed to refresh compile_commands.json (exit code: ' .. exit_code .. ')')
      end
    end,
    on_stdout = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line ~= '' then
            print(line)
          end
        end
      end
    end,
    on_stderr = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line ~= '' then
            print(line)
          end
        end
      end
    end,
  })
end

function M.open_build_file()
  local current_dir = vim.fn.expand('%:p:h')
  local current_file = vim.fn.expand('%:t')  -- Get filename with extension
  local build_file_path = nil
  local target_line = nil
  
  -- Check current directory
  local build_file = current_dir .. '/BUILD.bazel'
  if vim.fn.filereadable(build_file) == 1 then
    build_file_path = build_file
  else
    -- Check one directory up
    local parent_dir = vim.fn.fnamemodify(current_dir, ':h')
    build_file = parent_dir .. '/BUILD.bazel'
    if vim.fn.filereadable(build_file) == 1 then
      build_file_path = build_file
    end
  end
  
  if not build_file_path then
    -- Fallback to finding bazel files if build file not found
    fallback_to_sr_with_ext('bazel')
    return
  end
  
  -- Open the BUILD file
  vim.cmd('edit ' .. vim.fn.fnameescape(build_file_path))
  
  -- Search for the current filename in the BUILD file
  local line_num = vim.fn.search(vim.fn.escape(current_file, '.*[]^$\\'), 'w')
  if line_num > 0 then
    vim.fn.cursor(line_num, 1)
    vim.cmd('normal! zz')  -- Center the screen
  end
end

-- Internal helpers for label discovery
local function get_repo_root(start_dir)
  local out = vim.fn.systemlist({ 'git', '-C', start_dir, 'rev-parse', '--show-toplevel' })
  if vim.v.shell_error == 0 and out and out[1] and out[1] ~= '' then
    return out[1]
  end
  local ws = vim.fn.findfile('WORKSPACE', start_dir .. ';')
  if ws ~= '' then
    return vim.fn.fnamemodify(ws, ':h')
  end
  return vim.fn.getcwd()
end

local function to_relative_dir(path, root)
  if not path or not root then return path end
  if path:sub(1, #root) == root then
    local offset = #root
    if path:sub(offset + 1, offset + 1) == '/' then
      offset = offset + 1
    end
    local rel = path:sub(offset + 1)
    if rel == '' then return '' end
    return rel
  end
  return vim.fn.fnamemodify(path, ':.')
end

local function find_build_file_dir_for_current_or_parent()
  local current_dir = vim.fn.expand('%:p:h')
  local parent_dir = vim.fn.fnamemodify(current_dir, ':h')
  local candidates = {
    current_dir .. '/BUILD.bazel',
    current_dir .. '/BUILD',
    parent_dir .. '/BUILD.bazel',
    parent_dir .. '/BUILD',
  }
  for _, p in ipairs(candidates) do
    if vim.fn.filereadable(p) == 1 then
      return vim.fn.fnamemodify(p, ':h'), p
    end
  end
  return nil, nil
end

local function extract_quoted_strings(text)
  local items = {}
  for quote, inner in text:gmatch('([\'"])(.-)%1') do
    if inner and inner ~= '' then
      table.insert(items, inner)
    end
  end
  return items
end

local function glob_to_lua_pattern(glob)
  local pat = glob
  pat = pat:gsub('([%^%$%(%)%%%.%[%]%+%-])', '%%%1')
  pat = pat:gsub('%*%*', '\001')      -- temporary token for **
  pat = pat:gsub('%*', '[^/]*')       -- * matches any except /
  pat = pat:gsub('\001', '.*')        -- ** matches anything across dirs
  pat = pat:gsub('%?', '.')           -- ? matches single char
  return '^' .. pat .. '$'
end

local function matches_any_glob(rel_path, patterns)
  for _, g in ipairs(patterns) do
    local lp = glob_to_lua_pattern(g)
    if rel_path:match(lp) then
      return true
    end
  end
  return false
end

local function find_target_in_build(build_file_path, current_abs, build_dir)
  local lines = vim.fn.readfile(build_file_path)
  if not lines or #lines == 0 then return nil end

  local content = table.concat(lines, '\n')
  local rel_path
  if current_abs:sub(1, #build_dir) == build_dir then
    local offset = #build_dir
    if current_abs:sub(offset + 1, offset + 1) == '/' then
      offset = offset + 1
    end
    rel_path = current_abs:sub(offset + 0)
  else
    rel_path = vim.fn.fnamemodify(current_abs, ':t')
  end
  local file_tail = vim.fn.fnamemodify(current_abs, ':t')

  local best_match = nil

  local idx = 1
  while idx <= #lines do
    local line = lines[idx]
    local rule_start = line:match('^%s*([%w_]+)%s*%(')
    if rule_start then
      local depth = 0
      local start_idx = idx
      local block_lines = {}
      while idx <= #lines do
        local l = lines[idx]
        depth = depth + select(2, l:gsub('%(', '')) - select(2, l:gsub('%)', ''))
        table.insert(block_lines, l)
        if depth <= 0 and l:find('%)') then
          break
        end
        idx = idx + 1
      end
      local block = table.concat(block_lines, '\n')
      local name = block:match('name%s*=%s*[\'"]([^\'"]+)[\'"]')

      if name then
        local matched = false
        -- direct srcs list
        for srcs_block in block:gmatch('srcs%s*=%s*%b[]') do
          local items = extract_quoted_strings(srcs_block)
          for _, it in ipairs(items) do
            if it == rel_path or it == file_tail or vim.fn.fnamemodify(it, ':t') == file_tail then
              matched = true
              break
            end
          end
          if matched then break end
        end
        -- srcs = glob([...])
        if not matched then
          local glob_block = block:match('srcs%s*=%s*glob%s*%(%s*%b[]')
          if glob_block then
            local list_text = glob_block:match('%b[]')
            if list_text then
              local patterns = extract_quoted_strings(list_text)
              if matches_any_glob(rel_path, patterns) then
                matched = true
              end
            end
          end
        end
        -- Also consider hdrs
        if not matched then
          for hdrs_block in block:gmatch('hdrs%s*=%s*%b[]') do
            local items = extract_quoted_strings(hdrs_block)
            for _, it in ipairs(items) do
              if it == rel_path or it == file_tail or vim.fn.fnamemodify(it, ':t') == file_tail then
                matched = true
                break
              end
            end
            if matched then break end
          end
        end
        if matched then
          best_match = name
          break
        end
      end
    end
    idx = idx + 1
  end

  return best_match
end

local function build_label_for_target(build_dir, target_name, repo_root)
  local pkg = to_relative_dir(build_dir, repo_root)
  if not pkg or pkg == '' then
    return '//' .. ':' .. target_name
  end
  return '//' .. pkg .. ':' .. target_name
end

local function open_float_terminal_and_paste(cmd, execute)
  -- Open toggleterm float (same one as <leader>tk) and send command
  local terms = require('toggleterm.terminal')
  local term = terms.get(1)  -- Get terminal #1 (default)
  
  if not term then
    -- First time - create and open it
    vim.cmd('ToggleTerm direction=float')
    vim.defer_fn(function()
      local t = terms.get(1)
      if t and t.job_id then
        local keys = cmd .. (execute and '\r' or '')
        vim.api.nvim_chan_send(t.job_id, keys)
      end
    end, 150)
  else
    -- Terminal exists - open it if closed, then send command
    if not term:is_open() then
      term:open()
    end
    vim.defer_fn(function()
      if term.job_id then
        local keys = cmd .. (execute and '\r' or '')
        vim.api.nvim_chan_send(term.job_id, keys)
      end
    end, 100)
  end
end

local function open_split_terminal_and_paste(cmd, execute)
  vim.cmd('split | terminal')
  local keys = cmd .. (execute and '\n' or '')
  vim.api.nvim_feedkeys(keys, 'n', false)
end

-- Public: Find the Bazel target for the current file (in current or parent dir),
-- then open a terminal and paste `bazel build //pkg:target`.
-- mode can be 'build' or 'run'; defaults to 'build'.
-- use_float: if true, opens floating terminal; if false, opens split terminal.
function M.build_current_file_in_terminal(mode, use_float)
  local current_abs = vim.fn.expand('%:p')
  if current_abs == '' then
    print('No file')
    return
  end
  local build_dir, build_file = find_build_file_dir_for_current_or_parent()
  if not build_dir then
    print('No BUILD(.bazel) file in current or parent directory')
    return
  end
  local target = find_target_in_build(build_file, current_abs, build_dir)
  if not target or target == '' then
    print('No Bazel target in BUILD that includes current file')
    return
  end
  local repo_root = get_repo_root(build_dir)
  local label = build_label_for_target(build_dir, target, repo_root)
  local verb = (mode == 'run') and 'run' or 'build'
  local cmd = 'bazel ' .. verb .. ' ' .. label
  -- Execute immediately for build; for run just paste
  local should_execute = (verb == 'build')
  if use_float == false then
    open_split_terminal_and_paste(cmd, should_execute)
  else
    open_float_terminal_and_paste(cmd, should_execute)
  end
end

return M
