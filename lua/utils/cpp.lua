local M = {}

local telescope_files = require('utils.telescope_files')

local header_exts = { 'hh', 'h', 'hpp' }
local impl_exts = { 'cc', 'cpp', 'cxx' }

local header_set = {}
for _, ext in ipairs(header_exts) do header_set[ext] = true end
local impl_set = {}
for _, ext in ipairs(impl_exts) do impl_set[ext] = true end

local function fallback_to_sr_with_ext(ext_or_list)
  local current_dir = vim.fn.expand('%:p:h')
  local current_name = vim.fn.fnamemodify(current_dir, ':t')
  
  local ext_glob = '*.*'
  if type(ext_or_list) == 'string' then
    ext_glob = '*.' .. ext_or_list
  elseif type(ext_or_list) == 'table' and #ext_or_list > 0 then
    if #ext_or_list == 1 then
      ext_glob = '*.' .. ext_or_list[1]
    else
      ext_glob = '*.{' .. table.concat(ext_or_list, ',') .. '}'
    end
  end

  -- Ensure pattern is recursive by including /**/
  local glob = '**/' .. ext_glob
  
  telescope_files.find_files_with_glob(glob, nil, nil)
end

local function current_file_info()
  local path = vim.fn.expand('%:p')
  if path == '' then return nil end
  return {
    path = path,
    dir = vim.fn.fnamemodify(path, ':h'),
    name = vim.fn.fnamemodify(path, ':t'),
    stem = vim.fn.fnamemodify(path, ':t:r'),
    ext = vim.fn.expand('%:e'),
  }
end

local function strip_idl_suffix(name)
  local stripped = name:gsub('_idl$', '')
  return stripped ~= name and stripped or nil
end

local function edit_if_exists(path)
  if path and vim.fn.filereadable(path) == 1 then
    vim.cmd('edit ' .. vim.fn.fnameescape(path))
    return true
  end
  return false
end

local function open_with_exts(dir, stem, exts, label)
  if not stem or stem == '' then
    fallback_to_sr_with_ext(exts)
    return false
  end
  for _, ext in ipairs(exts) do
    local target = dir .. '/' .. stem .. '.' .. ext
    if edit_if_exists(target) then return true end
  end
  fallback_to_sr_with_ext(exts)
  return false
end

local function list_idl_files(dir)
  return vim.fn.readdir(dir, function(item)
    return item:match('_idl%.idl$')
  end)
end

local function unique_idl_stem(dir, opts)
  local matches = list_idl_files(dir)
  if #matches == 0 then
    if not (opts and opts.silent_missing) then
      -- vim.notify('No *_idl.idl files in directory', vim.log.levels.WARN)
    end
    return nil
  end
  if #matches > 1 then
    if not (opts and opts.silent_multiple) then
      vim.notify('Multiple *_idl.idl files found; open manually', vim.log.levels.WARN)
    end
    return nil
  end
  return matches[1]:gsub('_idl%.idl$', '')
end

local function fallback_dir_stem(dir)
  return vim.fn.fnamemodify(dir, ':t')
end

local function is_bazel_file(info)
  return info.name == 'BUILD'
    or info.name == 'BUILD.bazel'
    or info.ext == 'bazel'
end

local function stem_from_context(info)
  if header_set[info.ext] or impl_set[info.ext] then
    return info.stem
  end
  if info.ext == 'idl' then
    return strip_idl_suffix(info.stem) or info.stem
  end
  if is_bazel_file(info) then
    return unique_idl_stem(info.dir, { silent_missing = true, silent_multiple = true })
      or fallback_dir_stem(info.dir)
  end
  return info.stem
end

local function open_bazel_in_dir(dir)
  local targets = {
    dir .. '/BUILD.bazel',
    dir .. '/BUILD',
  }
  for _, path in ipairs(targets) do
    if edit_if_exists(path) then return true end
  end
  local bazels = vim.fn.readdir(dir, function(item)
    return item:match('%.bazel$')
  end)
  if #bazels > 0 then
    return edit_if_exists(dir .. '/' .. bazels[1])
  end
  return false
end

function M.toggle_header_impl()
  local info = current_file_info()
  if not info then
    fallback_to_sr_with_ext(header_exts) -- Default to header if unknown
    return
  end
  if not (header_set[info.ext] or impl_set[info.ext]) then
    fallback_to_sr_with_ext(header_exts) -- Default to header if not C++
    return
  end
  if header_set[info.ext] then
    open_with_exts(info.dir, info.stem, impl_exts, 'implementation')
  else
    open_with_exts(info.dir, info.stem, header_exts, 'header')
  end
end

function M.open_cpp_from_context()
  local info = current_file_info()
  if not info then
    fallback_to_sr_with_ext(impl_exts)
    return
  end
  if impl_set[info.ext] then
    vim.notify('Already in an implementation file', vim.log.levels.INFO)
    return
  end
  local stem = stem_from_context(info)
  if not stem then
    fallback_to_sr_with_ext(impl_exts)
    return
  end
  open_with_exts(info.dir, stem, impl_exts, 'implementation')
end

function M.open_header_from_context()
  local info = current_file_info()
  if not info then
    fallback_to_sr_with_ext(header_exts)
    return
  end
  if header_set[info.ext] then
    open_with_exts(info.dir, info.stem, impl_exts, 'implementation')
    return
  end
  local stem = stem_from_context(info)
  if not stem then
    fallback_to_sr_with_ext(header_exts)
    return
  end
  open_with_exts(info.dir, stem, header_exts, 'header')
end

function M.open_idl_from_context()
  local info = current_file_info()
  if not info then
    fallback_to_sr_with_ext('idl')
    return
  end
  if info.ext == 'idl' and info.stem:match('_idl$') then
    vim.notify('Already in an IDL file', vim.log.levels.INFO)
    return
  end
  local stem
  if is_bazel_file(info) then
    stem = unique_idl_stem(info.dir)
  else
    stem = stem_from_context(info)
  end
  if not stem or stem == '' then
    fallback_to_sr_with_ext('idl')
    return
  end
  local target = info.dir .. '/' .. stem .. '_idl.idl'
  if not edit_if_exists(target) then
    fallback_to_sr_with_ext('idl')
  end
end

function M.open_bazel_from_context()
  local info = current_file_info()
  if not info then
    fallback_to_sr_with_ext('bazel')
    return
  end
  local dir = info.dir
  while dir and dir ~= '' do
    if open_bazel_in_dir(dir) then
      return
    end
    local parent = vim.fn.fnamemodify(dir, ':h')
    if parent == dir then break end
    dir = parent
  end
  fallback_to_sr_with_ext('bazel')
end

return M
