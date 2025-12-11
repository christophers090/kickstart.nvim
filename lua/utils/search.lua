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

-- Tokenize arguments (handles quotes)
local function tokenize_args(prompt)
  if not prompt or prompt == '' then return {} end
  
  local args = {}
  local current_arg = ""
  local in_quote = false
  local quote_char = nil
  local escaped = false
  
  for i = 1, #prompt do
    local char = prompt:sub(i, i)
    
    if escaped then
      current_arg = current_arg .. char
      escaped = false
    elseif char == "\\" then
      escaped = true
      current_arg = current_arg .. char -- Keep escape char for rg to handle if needed
    elseif in_quote then
      if char == quote_char then
        in_quote = false
        quote_char = nil
      else
        current_arg = current_arg .. char
      end
    else
      if char == "'" or char == '"' then
        in_quote = true
        quote_char = char
      elseif char:match("%s") then
        if current_arg ~= "" then
          table.insert(args, current_arg)
          current_arg = ""
        end
      else
        current_arg = current_arg .. char
      end
    end
  end
  
  if current_arg ~= "" then
    table.insert(args, current_arg)
  end
  
  return args
end

-------------------------------------------------------------------------------
-- Cheatsheet UI
-------------------------------------------------------------------------------

local CHEATSHEET_LINES = {
  " Regex & Ripgrep Cheatsheet                                                      Always on: --smart-case --hidden --pcre2",
  " ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────",
  "  .   Any char           *   Zero or more       ^   Start of line      \\   Escape            -w   Word only          -A N  Lines after",
  "  \\d  Digit [0-9]        +   One or more        $   End of line        |   Or                -F   Literal string     -B N  Lines before",
  "  \\w  Word char          ?   Zero or one        ()  Group              []  Class             -v   Invert match       -C N  Context lines",
  "  \\s  Whitespace         {}  {n,m} count        (?! ) Neg Lookahead    [^] Neg Class         -u   Unrestricted       -U    Multiline",
  "  \\n  Newline            .*  Match any          (?= ) Pos Lookahead    \\b  Word boundary     -t   File type          -g    Glob filter",
}
local CHEATSHEET_WIDTH = 144
local CHEATSHEET_HEIGHT = #CHEATSHEET_LINES

-------------------------------------------------------------------------------
-- Tunable Layout Parameters
-------------------------------------------------------------------------------
local RESULTS_PREVIEW_WIDTH = 190  -- Total width of results + preview windows combined

local function show_cheatsheet()
  local buf = vim.api.nvim_create_buf(false, true)
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, CHEATSHEET_LINES)
  
  local col = math.floor((vim.o.columns - CHEATSHEET_WIDTH) / 2)
  
  local win = vim.api.nvim_open_win(buf, false, {
    relative = 'editor',
    row = vim.o.lines - CHEATSHEET_HEIGHT - 2,
    col = col,
    width = CHEATSHEET_WIDTH,
    height = CHEATSHEET_HEIGHT,
    style = 'minimal',
    border = 'rounded',
    focusable = false,
    zindex = 150, -- Above Telescope (usually 50-100)
  })
  return win
end

local function close_cheatsheet(win)
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
  end
end

-------------------------------------------------------------------------------
-- Custom Layout Strategy
-------------------------------------------------------------------------------

local function search_layout_strategy(picker, columns, lines, layout_config)
  -- Default layout config if nil
  layout_config = layout_config or {}

  -- Calculate available height: fill space from top down to the search prompt position
  -- The prompt is positioned just above the cheatsheet (CHEATSHEET_HEIGHT + 2 padding)
  local prompt_bottom_margin = CHEATSHEET_HEIGHT + 2
  local available_height = lines - prompt_bottom_margin
  
  -- Enforce max width and start from top
  local new_layout_config = vim.tbl_deep_extend("force", layout_config, {
    width = math.min(columns, RESULTS_PREVIEW_WIDTH),
    height = available_height,
    anchor = 'N', -- Top aligned
    mirror = false,
    prompt_position = "bottom", -- Force prompt to bottom in the calculation logic
  })

  local layout = require('telescope.pickers.layout_strategies').horizontal(picker, columns, lines, new_layout_config)
  
  -- Center the prompt above the cheatsheet
  local prompt_height = layout.prompt.height
  local prompt_line = lines - prompt_bottom_margin - prompt_height
  
  -- Use vim.o.columns to match the cheatsheet positioning exactly
  -- Add 2 to account for border offset difference between floating window and telescope
  local prompt_col = math.floor((vim.o.columns - CHEATSHEET_WIDTH) / 2) + 2
  
  layout.prompt.width = CHEATSHEET_WIDTH
  layout.prompt.col = prompt_col
  layout.prompt.line = prompt_line
  
  -- Results/preview should end just above the prompt
  -- Account for window borders and ensure no overlap with prompt
  local results_height = math.max(1, prompt_line - 4)
  
  -- Calculate widths and horizontal centering for results/preview
  local gap = 2  -- Gap between results and preview windows
  local total_width = math.min(vim.o.columns - 4, RESULTS_PREVIEW_WIDTH)
  local half_width = math.floor((total_width - gap) / 2)
  local start_col = math.floor((vim.o.columns - total_width) / 2)
  
  -- Adjust results window
  if layout.results then
    layout.results.line = 2 -- Start with top margin
    layout.results.height = results_height
    layout.results.width = half_width
    layout.results.col = start_col
  end
  
  -- Adjust preview window
  if layout.preview then
    layout.preview.line = 2 -- Start with top margin
    layout.preview.height = results_height
    layout.preview.width = half_width
    layout.preview.col = start_col + half_width + gap
  end
  
  return layout
end

-- Lazy registration helper
local function register_layout()
  require('telescope.pickers.layout_strategies').search_layout = search_layout_strategy
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

    local args = {
      'rg',
      '--color=never',
      '--no-heading',
      '--with-filename',
      '--line-number',
      '--column',
      '--smart-case',
      '--hidden',
      '--pcre2', -- Enable PCRE2 for lookaheads
    }

    -- Add default glob if provided (via scoped search)
    local normalized = normalize_glob(glob_pattern)
    if normalized and normalized ~= '' then
      table.insert(args, '-g')
      table.insert(args, normalized)
    end

    -- Tokenize and append user arguments
    if use_fuzzy then
       local actual_search = to_fuzzy_regex(search)
       table.insert(args, '--')
       table.insert(args, actual_search)
    else
       local user_args = tokenize_args(search)
       for _, arg in ipairs(user_args) do
         table.insert(args, arg)
       end
    end

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
    cwd: string - Directory to search in (absolute path)
    title: string - Custom picker title
]]
function M.find_files(opts)
  opts = opts or {}
  register_layout()
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
  local cwd = opts.cwd

  local finder = make_rg_files_finder(make_entry, default_glob, cwd)

  local title = opts.title or 'Find Files'

  -- Show cheatsheet and get window ID
  local cheatsheet_win = show_cheatsheet()

  pickers
    .new({}, {
      prompt_title = title .. ' (term  glob)',
      finder = finder,
      previewer = conf.file_previewer({}),
      sorter = conf.generic_sorter({}),
      layout_strategy = 'search_layout',
      layout_config = {
        height = 0.80,
        width = 0.95,
        anchor = 'N', -- Anchor to top to leave space at bottom
      },
      default_text = (default_term and default_glob) and (default_term .. '  ' .. default_glob)
        or (default_glob and ('  ' .. default_glob))
        or (default_term or nil),
      attach_mappings = function(prompt_bufnr, map)
        -- Close cheatsheet when prompt buffer closes
        vim.api.nvim_create_autocmd('BufWinLeave', {
          buffer = prompt_bufnr,
          callback = function()
            close_cheatsheet(cheatsheet_win)
          end,
          once = true,
        })

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
          return { prompt = term, updated_finder = make_rg_files_finder(make_entry, glob, cwd) }
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
    cwd: string - Directory to search in (absolute path)
    fuzzy: boolean - Use fuzzy matching (default: false)
    title: string - Custom picker title
]]
function M.grep(opts)
  opts = opts or {}
  register_layout()
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
  local cwd = opts.cwd  -- Only use cwd if explicitly passed

  local finder = make_rg_grep_finder(make_entry, nil, cwd, use_fuzzy)

  local title = opts.title or (use_fuzzy and 'Fuzzy Grep' or 'Live Grep')

  -- Build default text in rg native format
  local default_text = nil
  if default_term and default_glob then
    default_text = default_term .. ' -g "' .. default_glob .. '"'
  elseif default_glob then
    default_text = ' -g "' .. default_glob .. '"'
  elseif default_term then
    default_text = default_term
  end

  -- Show cheatsheet and get window ID
  local cheatsheet_win = show_cheatsheet()

  pickers
    .new({}, {
      prompt_title = title,
      finder = finder,
      previewer = conf.grep_previewer({}),
      sorter = require('telescope.sorters').empty(),
      layout_strategy = 'search_layout',
      layout_config = {
        height = 0.80,
        width = 0.95,
        anchor = 'N', -- Anchor to top to leave space at bottom
      },
      prompt_prefix = 'rg > ',
      default_text = default_text,
      attach_mappings = function(prompt_bufnr, map)
        -- Close cheatsheet when prompt buffer closes
        vim.api.nvim_create_autocmd('BufWinLeave', {
          buffer = prompt_bufnr,
          callback = function()
            close_cheatsheet(cheatsheet_win)
          end,
          once = true,
        })
        -- Move cursor to start so search term comes first
        vim.defer_fn(function()
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Home>', true, false, true), 'n', false)
        end, 20)
        return true
      end,
      on_input_filter_cb = function(prompt)
        return { prompt = prompt }
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

