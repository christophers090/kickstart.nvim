local M = {}

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
    print('Can\'t find build file')
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

return M
