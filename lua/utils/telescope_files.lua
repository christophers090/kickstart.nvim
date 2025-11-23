local M = {}

local function is_glob_like(text)
  if not text or text == '' then return false end
  return text:find('[%*%?%[%]{}!]') ~= nil
end

local function parse_prompt_for_files(prompt)
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

-- Normalize globs to be recursive like grep (prefix with "**/" unless already present)
local function add_recursive_prefix(glob)
  if not glob or glob == '' then return nil end
  glob = vim.trim(glob)
  local is_negated = false
  if glob:sub(1, 1) == '!' then
    is_negated = true
    glob = vim.trim(glob:sub(2))
  end
  if is_negated then
    glob = '!' .. glob
  end
  return glob
end

local function make_rg_files_finder(make_entry, glob_pattern, cwd)
  return require('telescope.finders').new_job(function(search)
    local args = {
      'rg',
      '--files',
      '--hidden',
      '--color=never',
    }
    local normalized_glob = add_recursive_prefix(glob_pattern)
    if normalized_glob and normalized_glob ~= '' then
      table.insert(args, '-g')
      table.insert(args, normalized_glob)
    end
    if cwd and cwd ~= '' then
      table.insert(args, cwd)
    end
    return args
  end, make_entry.gen_from_file({}))
end

function M.find_files_with_glob(default_glob, default_term, cwd)
  local pickers = require('telescope.pickers')
  local conf = require('telescope.config').values
  local make_entry = require('telescope.make_entry')

  local current_glob = default_glob
  local finder = make_rg_files_finder(make_entry, default_glob, cwd)

  pickers
    .new({}, {
      prompt_title = 'Find Files (term  glob: e.g. "foo  **/*.cc" or just "**/*.cc")',
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
        local term, glob = parse_prompt_for_files(prompt)
        if glob ~= current_glob then
          current_glob = glob
          return { prompt = term, updated_finder = make_rg_files_finder(make_entry, glob, cwd) }
        end
        return { prompt = term }
      end,
    })
    :find()
end

return M



