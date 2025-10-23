local M = {}

-- Build an rg finder that respects an optional glob, and only uses the
-- provided search term (so Telescope's sorter doesn't try to fuzzy match the glob).
local function add_recursive_prefix(glob)
  if not glob or glob == '' then return nil end
  glob = vim.trim(glob)
  local is_negated = false
  if glob:sub(1, 1) == '!' then
    is_negated = true
    glob = vim.trim(glob:sub(2))
  end
  if not glob:match('^%*%*/') then
    glob = '**/' .. glob
  end
  if is_negated then
    glob = '!' .. glob
  end
  return glob
end

local function make_rg_finder(make_entry, glob_pattern, dir)
  return require('telescope.finders').new_job(function(search)
    if not search or search == '' then
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
    local normalized_glob = add_recursive_prefix(glob_pattern)
    if normalized_glob and normalized_glob ~= '' then
      table.insert(args, '-g')
      table.insert(args, normalized_glob)
    end
    table.insert(args, '--')
    table.insert(args, search)
    if dir and dir ~= '' then
      table.insert(args, dir)
    end
    return args
  end, make_entry.gen_from_vimgrep({}))
end

-- Parse "term  glob" → term, glob (first double space only)
local function parse_prompt(prompt)
  local idx = prompt and prompt:find('  ', 1, true)
  if not idx then
    return vim.trim(prompt or ''), nil
  end
  local term = vim.trim(prompt:sub(1, idx - 1))
  local glob = vim.trim(prompt:sub(idx + 2))
  if glob == '' then glob = nil end
  return term, glob
end

-- Custom live grep with file pattern filtering using double space syntax
-- Example: "foo  *.cc" or "bar  **/*.{cc,h}"
function M.live_grep_with_glob(default_glob, default_term)
  local pickers = require('telescope.pickers')
  local conf = require('telescope.config').values
  local make_entry = require('telescope.make_entry')

  local current_glob = default_glob
  local finder = make_rg_finder(make_entry, default_glob, nil)

  pickers
    .new({}, {
      prompt_title = 'Live Grep (term  glob: e.g. "foo  *.cc")',
      finder = finder,
      previewer = conf.grep_previewer({}),
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
          return { prompt = term, updated_finder = make_rg_finder(make_entry, glob, nil) }
        end
        return { prompt = term }
      end,
    })
    :find()
end

-- Same but scoped to a specific directory
function M.live_grep_with_glob_in_dir(dir, default_glob, default_term)
  local pickers = require('telescope.pickers')
  local conf = require('telescope.config').values
  local make_entry = require('telescope.make_entry')

  local current_glob = default_glob
  local finder = make_rg_finder(make_entry, default_glob, dir)

  pickers
    .new({}, {
      prompt_title = 'Live Grep in ' .. dir .. ' (term  glob)',
      finder = finder,
      previewer = conf.grep_previewer({}),
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
          return { prompt = term, updated_finder = make_rg_finder(make_entry, glob, dir) }
        end
        return { prompt = term }
      end,
    })
    :find()
end

return M
