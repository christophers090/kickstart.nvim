return {
  'levouh/tint.nvim',
  event = 'VeryLazy',
  config = function()
    require('tint').setup({
      tint = -45, -- Darken colors, negative value (default -45)
      saturation = 0.6, -- Saturation (default 0.6)
      transforms = {
        require("tint.transforms").saturate(0.5),
        require("tint.transforms").tint_with_threshold(-45, "#000000", 100),
      },
      tint_background_colors = false, -- Disable background tinting to avoid "pane" effect
      highlight_ignore_patterns = { "WinSeparator", "Status.*" },
      window_ignore_function = function(winid)
        local bufid = vim.api.nvim_win_get_buf(winid)
        local buftype = vim.api.nvim_buf_get_option(bufid, "buftype")
        local floating = vim.api.nvim_win_get_config(winid).relative ~= ""

        -- Do not tint floating windows or terminal
        if floating or buftype == "terminal" then
          return true
        end

        return false
      end
    })
  end
}

