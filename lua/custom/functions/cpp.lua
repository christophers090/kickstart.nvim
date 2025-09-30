local M = {}

function M.toggle_header_impl()
  local current_file = vim.fn.expand('%:p')
  local base = vim.fn.expand('%:p:r')
  local ext = vim.fn.expand('%:e')
  
  local alternate_extensions = {
    cc = { 'h', 'hpp', 'hh' },
    cpp = { 'h', 'hpp', 'hh' },
    cxx = { 'h', 'hpp', 'hh' },
    h = { 'cc', 'cpp', 'cxx' },
    hpp = { 'cc', 'cpp', 'cxx' },
    hh = { 'cc', 'cpp', 'cxx' }
  }
  
  local target_exts = alternate_extensions[ext]
  if not target_exts then
    print('Not a C++ file')
    return
  end
  
  for _, target_ext in ipairs(target_exts) do
    local target_file = base .. '.' .. target_ext
    if vim.fn.filereadable(target_file) == 1 then
      vim.cmd('edit ' .. vim.fn.fnameescape(target_file))
      return
    end
  end
  
  print('Corresponding file not found')
end

return M

