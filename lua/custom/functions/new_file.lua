local M = {}

function M.create_new_file()
  -- Get the word under cursor as default
  local word = vim.fn.expand('<cword>')
  vim.ui.input({ prompt = 'New file: ', default = word }, function(input)
    if input then
      vim.cmd('e ' .. input)
    end
  end)
end

return M
