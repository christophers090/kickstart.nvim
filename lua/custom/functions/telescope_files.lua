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

local function make_rg_files_finder(make_entry, glob_pattern, cwd)
  return require('telescope.finders').new_job(function(search)
    local args = {
      'rg',
      '--files',
      '--hidden',
      '--color=never',
    }
    if glob_pattern and glob_pattern ~= '' then
      table.insert(args, '-g')
      table.insert(args, glob_pattern)
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



