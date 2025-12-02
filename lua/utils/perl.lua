-- Interactive perl regex picker with live preview and cheatsheet
local M = {}

-- Compact cheatsheet - PCRE syntax + common flags
local cheatsheet = {
  -- Column 1: Basics
  { pattern = '.',       desc = 'Any char' },
  { pattern = '\\d',     desc = 'Digit' },
  { pattern = '\\w',     desc = 'Word char' },
  { pattern = '\\s',     desc = 'Whitespace' },
  { pattern = '*',       desc = '0+ greedy' },
  { pattern = '+',       desc = '1+ greedy' },
  { pattern = '?',       desc = '0 or 1' },
  { pattern = '*?',      desc = '0+ lazy' },
  { pattern = '+?',      desc = '1+ lazy' },
  { pattern = '{n,m}',   desc = 'Repeat n-m' },
  { pattern = '-pe',     desc = 'Loop+print' },
  { pattern = '-pi -e',  desc = 'In-place edit' },
  -- Column 2: Anchors & groups
  { pattern = '^',       desc = 'Line start' },
  { pattern = '$',       desc = 'Line end' },
  { pattern = '\\b',     desc = 'Word boundary' },
  { pattern = '()',      desc = 'Capture group' },
  { pattern = '(?:)',    desc = 'Non-capture' },
  { pattern = '|',       desc = 'Alternation' },
  { pattern = '[]',      desc = 'Char class' },
  { pattern = '[^]',     desc = 'Negated class' },
  { pattern = '-ni -e',  desc = 'Delete lines' },
  { pattern = '-ne',     desc = 'Loop no print' },
  { pattern = '/g',      desc = 'Global (all)' },
  { pattern = '/i',      desc = 'Case insens.' },
  -- Column 3: Replace & advanced
  { pattern = '$1',      desc = 'Backref 1' },
  { pattern = '\\u',     desc = 'Upper next' },
  { pattern = '\\l',     desc = 'Lower next' },
  { pattern = '\\U',     desc = 'Upper til \\E' },
  { pattern = '\\L',     desc = 'Lower til \\E' },
  { pattern = '(?=)',    desc = 'Lookahead' },
  { pattern = '(?!)',    desc = 'Neg lookahead' },
  { pattern = '(?<=)',   desc = 'Lookbehind' },
  { pattern = '(?<!)',   desc = 'Neg lookbehind' },
  { pattern = '/m',      desc = 'Multiline ^$' },
}

-- Parse prompt into search and replace parts
-- Format: search/replace or just search
local function parse_prompt(prompt)
  if not prompt or prompt == '' then
    return nil, nil
  end
  -- Find unescaped /
  local i = 1
  while i <= #prompt do
    local c = prompt:sub(i, i)
    if c == '\\' then
      i = i + 2
    elseif c == '/' then
      local search = prompt:sub(1, i - 1)
      local replace = prompt:sub(i + 1)
      return search, replace
    else
      i = i + 1
    end
  end
  return prompt, nil
end

-- Get match positions using perl, with optional line range restriction
local function get_matches_with_positions(filepath, search, replace, start_line, end_line)
  if not search or search == '' then
    return {}
  end

  -- Perl script that outputs: line_num, match_start, match_end, replacement_text
  -- For each match on each line, optionally restricted to line range
  local line_filter = ''
  if start_line and end_line then
    line_filter = string.format('next unless $. >= %d && $. <= %d;', start_line, end_line)
  end

  local perl_script
  if replace then
    perl_script = string.format([[
      while (<>) {
        %s
        my $line = $_;
        chomp $line;
        my $lnum = $.;
        my @matches;
        my $pos = 0;
        my $result = $line;
        # Collect all matches first
        while ($line =~ /(%s)/g) {
          my $match = $1;
          my $end = pos($line);
          my $start = $end - length($match);
          push @matches, [$start, $end, $match];
        }
        if (@matches) {
          # Get the substituted result
          $result = $line;
          $result =~ s/%s/%s/g;
          # Output format: LNUM|original_line|result_line|start1,end1;start2,end2;...
          my $positions = join(";", map { $_->[0] . "," . $_->[1] } @matches);
          print "$lnum|$line|$result|$positions\n";
        }
      }
    ]], line_filter, search, search, replace)
  else
    perl_script = string.format([[
      while (<>) {
        %s
        my $line = $_;
        chomp $line;
        my $lnum = $.;
        my @matches;
        while ($line =~ /(%s)/g) {
          my $match = $1;
          my $end = pos($line);
          my $start = $end - length($match);
          push @matches, [$start, $end];
        }
        if (@matches) {
          my $positions = join(";", map { $_->[0] . "," . $_->[1] } @matches);
          print "$lnum|$line||$positions\n";
        }
      }
    ]], line_filter, search)
  end

  local cmd = string.format('perl -e %s %s 2>&1', vim.fn.shellescape(perl_script), vim.fn.shellescape(filepath))
  local handle = io.popen(cmd)
  if not handle then
    return {}
  end

  local results = {}
  for line in handle:lines() do
    -- Parse: LNUM|original|result|positions
    local lnum, original, result, positions = line:match('^(%d+)|(.*)|(.*)|(.*)$')
    if lnum then
      local match_ranges = {}
      for start_pos, end_pos in positions:gmatch('(%d+),(%d+)') do
        table.insert(match_ranges, { tonumber(start_pos), tonumber(end_pos) })
      end
      table.insert(results, {
        lnum = tonumber(lnum),
        original = original,
        result = result,
        ranges = match_ranges,
      })
    end
  end
  handle:close()

  return results
end

-- Format cheatsheet into 3-column layout
local function format_cheatsheet(width)
  local lines = {}
  local col_width = math.floor((width - 6) / 3)
  local items_per_col = math.ceil(#cheatsheet / 3)

  for row = 1, items_per_col do
    local parts = {}
    for col = 0, 2 do
      local idx = row + (col * items_per_col)
      if idx <= #cheatsheet then
        local item = cheatsheet[idx]
        local entry = string.format('%-7s %s', item.pattern, item.desc)
        if #entry > col_width then
          entry = entry:sub(1, col_width)
        else
          entry = entry .. string.rep(' ', col_width - #entry)
        end
        table.insert(parts, entry)
      end
    end
    table.insert(lines, table.concat(parts, '  '))
  end

  return lines
end

function M.run()
  local original_bufnr = vim.api.nvim_get_current_buf()
  local filepath = vim.fn.expand('%:p')
  local filename = vim.fn.expand('%:t')

  -- Check for visual selection
  local mode = vim.fn.mode()
  local start_line, end_line
  local is_visual = mode == 'v' or mode == 'V' or mode == '\22'  -- \22 is <C-v>

  if is_visual then
    -- Get visual selection range
    -- Exit visual mode first to set '< and '> marks
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'nx', false)
    start_line = vim.fn.line("'<")
    end_line = vim.fn.line("'>")
  end

  -- Get the lines to show (either selected or all)
  local original_lines
  if start_line and end_line then
    original_lines = vim.api.nvim_buf_get_lines(original_bufnr, start_line - 1, end_line, false)
  else
    original_lines = vim.api.nvim_buf_get_lines(original_bufnr, 0, -1, false)
  end

  -- Create highlight namespace
  local ns = vim.api.nvim_create_namespace('perl_preview')

  -- Create the floating windows manually for custom layout
  local width = math.floor(vim.o.columns * 0.85)
  local height = math.floor(vim.o.lines * 0.85)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  -- Calculate heights for each section
  local cheatsheet_lines = format_cheatsheet(width)
  local cheatsheet_height = #cheatsheet_lines
  local prompt_height = 3
  local preview_height = height - cheatsheet_height - prompt_height - 4

  -- Create preview buffer and window (TOP)
  local preview_buf = vim.api.nvim_create_buf(false, true)
  local preview_win = vim.api.nvim_open_win(preview_buf, false, {
    relative = 'editor',
    row = row,
    col = col,
    width = width,
    height = preview_height,
    style = 'minimal',
    border = 'rounded',
    title = ' Preview ',
    title_pos = 'center',
  })

  -- Set filetype for syntax highlighting
  local ft = vim.bo[original_bufnr].filetype
  if ft and ft ~= '' then
    vim.bo[preview_buf].filetype = ft
  end

  -- Build prompt title with line range if visual
  local prompt_title
  if start_line and end_line then
    prompt_title = string.format(' Perl: s/search/replace/g (%s:%d-%d) ', filename, start_line, end_line)
  else
    prompt_title = string.format(' Perl: s/search/replace/g (%s) ', filename)
  end

  -- Create prompt buffer and window (MIDDLE)
  local prompt_buf = vim.api.nvim_create_buf(false, true)
  local prompt_win = vim.api.nvim_open_win(prompt_buf, true, {
    relative = 'editor',
    row = row + preview_height + 2,
    col = col,
    width = width,
    height = 1,
    style = 'minimal',
    border = 'rounded',
    title = prompt_title,
    title_pos = 'center',
  })

  -- Create cheatsheet buffer and window (BOTTOM)
  local cheatsheet_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(cheatsheet_buf, 0, -1, false, cheatsheet_lines)
  vim.bo[cheatsheet_buf].modifiable = false

  local cheatsheet_win = vim.api.nvim_open_win(cheatsheet_buf, false, {
    relative = 'editor',
    row = row + preview_height + prompt_height + 3,
    col = col,
    width = width,
    height = #cheatsheet_lines,
    style = 'minimal',
    border = 'rounded',
    title = ' PCRE Cheatsheet ',
    title_pos = 'center',
  })

  -- Style the cheatsheet
  vim.wo[cheatsheet_win].winhl = 'Normal:Comment'

  -- Set up prompt buffer
  vim.bo[prompt_buf].buftype = 'prompt'
  vim.fn.prompt_setprompt(prompt_buf, 's/')

  -- Track current state
  local current_search = ''
  local current_replace = nil

  -- Update preview function
  local function update_preview()
    local line = vim.api.nvim_buf_get_lines(prompt_buf, 0, 1, false)[1] or ''
    -- Remove the prompt prefix
    local input = line:gsub('^s/', '')

    -- Clear previous highlights
    vim.api.nvim_buf_clear_namespace(preview_buf, ns, 0, -1)

    if input == '' then
      -- Show full file (or selected lines) when nothing typed
      vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, original_lines)
      current_search = ''
      current_replace = nil
      return
    end

    local search, replace = parse_prompt(input)
    current_search = search
    current_replace = replace

    if not search or search == '' then
      vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, original_lines)
      return
    end

    -- Get matches with positions (restricted to line range if visual)
    local matches = get_matches_with_positions(filepath, search, replace, start_line, end_line)

    if #matches == 0 then
      vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, { '  No matches found' })
      return
    end

    local preview_lines = {}
    local highlights = {}  -- { line_idx, start_col, end_col, hl_group }

    for _, m in ipairs(matches) do
      local prefix = string.format('%4d: ', m.lnum)
      local line_idx = #preview_lines

      if replace and m.result ~= '' and m.original ~= m.result then
        -- Show the result line with replacements highlighted
        table.insert(preview_lines, prefix .. m.result)

        -- Calculate where replacements are in the result
        -- We need to track offset changes as we replace
        local offset = 0
        for _, range in ipairs(m.ranges) do
          local start_pos, end_pos = range[1], range[2]
          local match_text = m.original:sub(start_pos + 1, end_pos)
          
          -- Apply perl substitution to just this match to get actual replacement
          local cmd = string.format("echo %s | perl -pe %s 2>/dev/null",
            vim.fn.shellescape(match_text),
            vim.fn.shellescape(string.format("s/%s/%s/g", search, replace)))
          local handle = io.popen(cmd)
          if handle then
            local replacement = handle:read('*l') or replace
            handle:close()
            
            local hl_start = #prefix + start_pos + offset
            local hl_end = hl_start + #replacement
            table.insert(highlights, { line_idx, hl_start, hl_end, 'DiffAdd' })
            offset = offset + (#replacement - (end_pos - start_pos))
          end
        end
      else
        -- Search only - highlight matches in original line
        table.insert(preview_lines, prefix .. m.original)

        for _, range in ipairs(m.ranges) do
          local hl_start = #prefix + range[1]
          local hl_end = #prefix + range[2]
          table.insert(highlights, { line_idx, hl_start, hl_end, 'Search' })
        end
      end
    end

    vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, preview_lines)

    -- Apply highlights
    for _, hl in ipairs(highlights) do
      local line_idx, start_col, end_col, hl_group = hl[1], hl[2], hl[3], hl[4]
      pcall(vim.api.nvim_buf_add_highlight, preview_buf, ns, hl_group, line_idx, start_col, end_col)
    end
  end

  -- Cleanup function
  local function cleanup()
    pcall(vim.api.nvim_win_close, preview_win, true)
    pcall(vim.api.nvim_win_close, prompt_win, true)
    pcall(vim.api.nvim_win_close, cheatsheet_win, true)
    pcall(vim.api.nvim_buf_delete, preview_buf, { force = true })
    pcall(vim.api.nvim_buf_delete, prompt_buf, { force = true })
    pcall(vim.api.nvim_buf_delete, cheatsheet_buf, { force = true })
  end

  -- Set up autocmd to update preview on text change
  local augroup = vim.api.nvim_create_augroup('PerlPreview', { clear = true })
  vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, {
    group = augroup,
    buffer = prompt_buf,
    callback = update_preview,
  })

  vim.api.nvim_create_autocmd('BufLeave', {
    group = augroup,
    buffer = prompt_buf,
    callback = function()
      vim.api.nvim_del_augroup_by_id(augroup)
      cleanup()
    end,
  })

  -- Handle Enter to execute
  vim.keymap.set('i', '<CR>', function()
    if not current_search or current_search == '' then
      print('No search pattern provided')
      return
    end

    if not current_replace then
      print('No replacement provided (use search/replace format)')
      return
    end

    vim.api.nvim_del_augroup_by_id(augroup)
    cleanup()

    -- Execute perl substitution in-place
    -- If we have a line range, we need to only substitute on those lines
    local perl_cmd
    if start_line and end_line then
      -- Use perl to only modify lines in range
      perl_cmd = string.format('perl -pi -e %s %s',
        vim.fn.shellescape(string.format("s/%s/%s/g if $. >= %d && $. <= %d", 
          current_search, current_replace, start_line, end_line)),
        vim.fn.shellescape(filepath))
    else
      perl_cmd = string.format('perl -pi -e %s %s',
        vim.fn.shellescape(string.format("s/%s/%s/g", current_search, current_replace)),
        vim.fn.shellescape(filepath))
    end

    local result = vim.fn.system(perl_cmd)
    if vim.v.shell_error ~= 0 then
      print(string.format('Error: %s', result))
    else
      -- Reload buffer
      vim.cmd('edit!')
      if start_line and end_line then
        print(string.format("Executed: perl -pi -e 's/%s/%s/g' on lines %d-%d", 
          current_search, current_replace, start_line, end_line))
      else
        print(string.format("Executed: perl -pi -e 's/%s/%s/g'", current_search, current_replace))
      end
    end
  end, { buffer = prompt_buf })

  -- Handle Escape to cancel
  vim.keymap.set({ 'i', 'n' }, '<Esc>', function()
    vim.api.nvim_del_augroup_by_id(augroup)
    cleanup()
  end, { buffer = prompt_buf })

  -- Start in insert mode
  vim.cmd('startinsert!')

  -- Initial preview - show full file or selected lines
  update_preview()
end

return M
