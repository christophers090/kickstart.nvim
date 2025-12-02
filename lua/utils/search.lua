-- Unified search utility for Telescope-based file and grep searches
-- Consolidates telescope_files.lua and telescope_grep.lua functionality

local M = {}

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------

local function is_glob_like(text)
  if not text or text == '' then return false end
  return text:find('[%*%?%[%]{}!]') ~= nil
end

-- Parse "term  glob" → term, glob (first double space separates them)
local function parse_prompt(prompt)
  if not prompt then return '', nil end
  local idx = prompt:find('  ', 1, true)
  if idx then
    local term = vim.trim(prompt:sub(1, idx - 1))
    local glob = vim.trim(prompt:sub(idx + 2))
    if glob == '' then glob = nil end
    return term, glob
  end
  if is_glob_like(prompt) then
    return '', vim.trim(prompt)
  end
  return vim.trim(prompt), nil
end

-- Normalize glob (handle negation, etc.)
local function normalize_glob(glob)
  if not glob or glob == '' then return nil end
  return vim.trim(glob)
end

-- Convert input to fuzzy regex like "a.*b.*c"
local function to_fuzzy_regex(term)
  if not term or term == '' then return nil end
  local function escape_regex(text)
    return (text or ''):gsub('([%^%$%.%*%+%?%(%)%[%]%{%}%|%\\])', '\\%1')
  end
  local pieces = {}
  for token in term:gmatch('%S+') do
    local escaped = escape_regex(token)
    local chars = {}
    for ch in escaped:gmatch('.') do
      table.insert(chars, ch)
    end
    table.insert(pieces, table.concat(chars, '.*'))
  end
  return table.concat(pieces, '.*')
end

-------------------------------------------------------------------------------
-- Directory Resolution
-------------------------------------------------------------------------------

-- Get git or bazel workspace root
function M.get_repo_root(start_dir)
  start_dir = start_dir or vim.fn.expand('%:p:h')
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

-- Get current buffer's directory
function M.get_current_dir()
  return vim.fn.expand('%:p:h')
end

-- Get parent of current buffer's directory
function M.get_parent_dir()
  return vim.fn.fnamemodify(vim.fn.expand('%:p:h'), ':h')
end

-- Resolve directory based on scope
-- scope: 'current', 'parent', 'root', or nil (defaults to root)
function M.resolve_dir(scope)
  if scope == 'current' then
    return M.get_current_dir()
  elseif scope == 'parent' then
    return M.get_parent_dir()
  elseif scope == 'root' then
    return M.get_repo_root()
  end
  return nil -- Let telescope use its default (usually cwd)
end

-------------------------------------------------------------------------------
-- Finder Factories
-------------------------------------------------------------------------------

local function make_rg_files_finder(make_entry, glob_pattern, cwd)
  return require('telescope.finders').new_job(function(search)
    local args = {
      'rg',
      '--files',
      '--hidden',
      '--color=never',
    }
    local normalized = normalize_glob(glob_pattern)
    if normalized and normalized ~= '' then
      table.insert(args, '-g')
      table.insert(args, normalized)
    end
    if cwd and cwd ~= '' then
      table.insert(args, cwd)
    end
    return args
  end, make_entry.gen_from_file({}))
end

local function make_rg_grep_finder(make_entry, glob_pattern, cwd, use_fuzzy)
  return require('telescope.finders').new_job(function(search)
    if not search or search == '' then
      return nil
    end
    local actual_search = use_fuzzy and to_fuzzy_regex(search) or search
    if not actual_search or actual_search == '' then
      return nil
    end
    local args = {
      'rg',
      '--color=never',
      '--no-heading',
      '--with-filename',
      '--line-number',
      '--column',
      '--smart-case',
      '--hidden',
    }
    local normalized = normalize_glob(glob_pattern)
    if normalized and normalized ~= '' then
      table.insert(args, '-g')
      table.insert(args, normalized)
    end
    table.insert(args, '--')
    table.insert(args, actual_search)
    if cwd and cwd ~= '' then
      table.insert(args, cwd)
    end
    return args
  end, make_entry.gen_from_vimgrep({}))
end

-------------------------------------------------------------------------------
-- Public API
-------------------------------------------------------------------------------

-- Helper to build glob from scope
local function build_scope_glob(scope, ext_pattern)
  ext_pattern = ext_pattern or '*.*'
  if scope == 'current' then
    local dir_name = vim.fn.fnamemodify(M.get_current_dir(), ':t')
    if dir_name and dir_name ~= '' then
      return '**/' .. dir_name .. '/**/' .. ext_pattern
    end
  elseif scope == 'parent' then
    local parent_name = vim.fn.fnamemodify(M.get_parent_dir(), ':t')
    if parent_name and parent_name ~= '' then
      return '**/' .. parent_name .. '/**/' .. ext_pattern
    end
  end
  return '**/' .. ext_pattern
end

--[[
  M.find_files(opts)
  
  Options:
    glob: string - File pattern (e.g., "*.cc", "**/*.h")
    term: string - Pre-filled search term
    scope: string - 'current', 'parent', 'root' - builds glob with directory name
    ext: string - Extension pattern for scope (default: "*.*")
    title: string - Custom picker title
]]
function M.find_files(opts)
  opts = opts or {}
  local pickers = require('telescope.pickers')
  local conf = require('telescope.config').values
  local make_entry = require('telescope.make_entry')

  -- Build glob from scope if provided, otherwise use explicit glob
  local default_glob = opts.glob
  if opts.scope and not default_glob then
    default_glob = build_scope_glob(opts.scope, opts.ext)
  end
  
  local default_term = opts.term
  local current_glob = default_glob

  local finder = make_rg_files_finder(make_entry, default_glob, nil)

  local title = opts.title or 'Find Files'

  pickers
    .new({}, {
      prompt_title = title .. ' (term  glob)',
      finder = finder,
      previewer = conf.file_previewer({}),
      sorter = conf.generic_sorter({}),
      default_text = (default_term and default_glob) and (default_term .. '  ' .. default_glob)
        or (default_glob and ('  ' .. default_glob))
        or (default_term or nil),
      attach_mappings = function(prompt_bufnr, map)
        if default_glob and not default_term then
          vim.defer_fn(function()
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Home>', true, false, true), 'n', false)
          end, 20)
        end
        return true
      end,
      on_input_filter_cb = function(prompt)
        local term, glob = parse_prompt(prompt)
        if glob ~= current_glob then
          current_glob = glob
          return { prompt = term, updated_finder = make_rg_files_finder(make_entry, glob, nil) }
        end
        return { prompt = term }
      end,
    })
    :find()
end

--[[
  M.grep(opts)
  
  Options:
    glob: string - File pattern (e.g., "*.cc", "**/*.h")
    term: string - Pre-filled search term
    scope: string - 'current', 'parent', 'root' - builds glob with directory name
    ext: string - Extension pattern for scope (default: "*.*")
    fuzzy: boolean - Use fuzzy matching (default: false)
    title: string - Custom picker title
]]
function M.grep(opts)
  opts = opts or {}
  local pickers = require('telescope.pickers')
  local conf = require('telescope.config').values
  local make_entry = require('telescope.make_entry')

  -- Build glob from scope if provided, otherwise use explicit glob
  local default_glob = opts.glob
  if opts.scope and not default_glob then
    default_glob = build_scope_glob(opts.scope, opts.ext)
  end
  
  local default_term = opts.term
  local use_fuzzy = opts.fuzzy or false
  local current_glob = default_glob

  local finder = make_rg_grep_finder(make_entry, default_glob, nil, use_fuzzy)

  local title = opts.title or (use_fuzzy and 'Fuzzy Grep' or 'Live Grep')

  pickers
    .new({}, {
      prompt_title = title .. ' (term  glob)',
      finder = finder,
      previewer = conf.grep_previewer({}),
      sorter = require('telescope.sorters').empty(),
      default_text = (default_term and default_glob) and (default_term .. '  ' .. default_glob)
        or (default_glob and ('  ' .. default_glob))
        or (default_term or nil),
      attach_mappings = function(prompt_bufnr, map)
        if default_glob and not default_term then
          vim.defer_fn(function()
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Home>', true, false, true), 'n', false)
          end, 20)
        end
        return true
      end,
      on_input_filter_cb = function(prompt)
        local term, glob = parse_prompt(prompt)
        if glob ~= current_glob then
          current_glob = glob
          return { prompt = term, updated_finder = make_rg_grep_finder(make_entry, glob, nil, use_fuzzy) }
        end
        return { prompt = term }
      end,
    })
    :find()
end

-------------------------------------------------------------------------------
-- Convenience Wrappers (for common use cases)
-------------------------------------------------------------------------------

-- Find files with extension filter, using glob pattern with directory name
function M.find_files_by_ext(ext_or_list, search_dir)
  search_dir = search_dir or M.get_current_dir()
  local dir_name = vim.fn.fnamemodify(search_dir, ':t')
  
  -- Build extension pattern
  local ext_pattern
  if type(ext_or_list) == 'string' then
    ext_pattern = '*.' .. ext_or_list
  elseif type(ext_or_list) == 'table' and #ext_or_list > 0 then
    if #ext_or_list == 1 then
      ext_pattern = '*.' .. ext_or_list[1]
    else
      ext_pattern = '*.{' .. table.concat(ext_or_list, ',') .. '}'
    end
  else
    ext_pattern = '*.*'
  end
  
  -- Build full glob with directory name embedded
  local glob
  if dir_name and dir_name ~= '' then
    glob = '**/' .. dir_name .. '/**/' .. ext_pattern
  else
    glob = '**/' .. ext_pattern
  end
  
  -- Search with the glob pattern (no cwd limiting)
  M.find_files({ glob = glob })
end

return M

