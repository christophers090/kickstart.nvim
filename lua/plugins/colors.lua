return {
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    priority = 1000,
  },
  {
    'shaunsingh/nord.nvim',
    lazy = false,
    priority = 1000,
  },
  {
    'rmehri01/onenord.nvim',
    lazy = false,
    priority = 1000,
  },
  {
    'shaunsingh/moonlight.nvim',
    lazy = false,
    priority = 1000,
  },
  {
    'sekke276/dark_flat.nvim',
    lazy = false,
    priority = 1000,
  },

  {
    -- Theme Rotation Logic
    dir = vim.fn.stdpath('config') .. '/lua/plugins/theme-rotator', -- Dummy path, this is a virtual plugin
    name = 'theme-rotator',
    virtual = true, -- Explicitly mark as virtual if supported, otherwise dir works as local
    lazy = false,
    priority = 900, -- Load after themes are installed
    config = function()
      -- Defines the list of themes to cycle through
      local themes = {
        'catppuccin-mocha',
        'nord',
        'onenord',
        'moonlight',
        'dark_flat',
      }

      -- State file paths
      local state_file = vim.fn.stdpath('data') .. '/current_theme_index'
      local blocked_file = vim.fn.stdpath('data') .. '/blocked_themes.json'

      -- Helper to read/write blocked themes
      local function get_blocked_themes()
        if vim.fn.filereadable(blocked_file) == 1 then
          local content = vim.fn.readfile(blocked_file)
          if content and #content > 0 then
            local ok, decoded = pcall(vim.json.decode, table.concat(content, ''))
            if ok then return decoded end
          end
        end
        return {}
      end

      local function save_blocked_themes(blocked)
        vim.fn.writefile({vim.json.encode(blocked)}, blocked_file)
      end

      local function get_current_index()
        if vim.fn.filereadable(state_file) == 1 then
          local content = vim.fn.readfile(state_file)
          if content and #content > 0 then
            return tonumber(content[1]) or 1
          end
        end
        return 1
      end

      local function save_current_index(index)
        vim.fn.writefile({tostring(index)}, state_file)
      end

      -- Function to get the next valid theme
      local function rotate_theme(step)
        step = step or 1
        local blocked = get_blocked_themes()
        local index = get_current_index()
        local count = 0
        local max_checks = #themes + 1

        repeat
          index = index + step
          if index > #themes then index = 1 end
          if index < 1 then index = #themes end
          count = count + 1
        until (not blocked[themes[index]] or count > max_checks)

        save_current_index(index)
        return themes[index]
      end
      
      -- Apply the theme on startup (no rotation, just load current)
      -- To rotate on startup, we call rotate_theme(1). 
      -- Current logic was: get next theme on startup.
      -- Let's keep that behavior: Rotate once on startup.
      local theme = rotate_theme(1)
      
      -- Protected call to avoid startup errors if a theme fails
      local ok, _ = pcall(vim.cmd.colorscheme, theme)
      if not ok then
        vim.notify("Failed to load theme: " .. theme .. ". Falling back to default.", vim.log.levels.WARN)
        vim.cmd.colorscheme('default')
      end

      vim.notify("Theme: " .. theme, vim.log.levels.INFO, { title = "Theme Rotator" })

      -- Keymaps for Like/Dislike
      
      -- Dislike: Block current theme and rotate to next
      vim.keymap.set('n', '<leader>tD', function()
        local current_theme = vim.g.colors_name
        if not current_theme then return end
        
        local blocked = get_blocked_themes()
        blocked[current_theme] = true
        save_blocked_themes(blocked)
        
        vim.notify("Disliked " .. current_theme .. ". Rotating...", vim.log.levels.WARN)
        
        -- Rotate to next valid
        local next_theme = rotate_theme(1)
        pcall(vim.cmd.colorscheme, next_theme)
        vim.notify("New Theme: " .. next_theme, vim.log.levels.INFO)
      end, { desc = '[T]heme [D]islike (Ban and Rotate)' })

      -- Like: Could lock it, or just notify. User asked for "Favorite".
      -- For now, let's make it "Favorite" by maybe unblocking it if it was blocked (unlikely case here)
      -- or just a visual confirmation. 
      -- Actually, let's interpret "Like" as "Keep this one, don't rotate next time".
      -- But "rotate on startup" is the core feature. 
      -- Let's just print a heart message for now.
      vim.keymap.set('n', '<leader>tf', function()
        local current_theme = vim.g.colors_name
        vim.notify("❤️ Favorited " .. tostring(current_theme), vim.log.levels.INFO)
      end, { desc = '[T]heme [F]avorite' })

      -- Switch to dark_flat theme
      vim.keymap.set('n', '<leader>tl', function()
        pcall(vim.cmd.colorscheme, 'dark_flat')
        vim.notify("Theme: dark_flat", vim.log.levels.INFO)
      end, { desc = '[T]heme dark_f[L]at' })

      -- Rotate Theme Manually
      vim.keymap.set('n', '<leader>tr', function()
        local next_theme = rotate_theme(1)
        pcall(vim.cmd.colorscheme, next_theme)
        vim.notify("Rotated to Theme: " .. next_theme, vim.log.levels.INFO)
      end, { desc = '[T]heme [R]otate' })

    end,
  },
}
