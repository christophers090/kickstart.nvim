return {
  "shellRaining/hlchunk.nvim",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    require("hlchunk").setup({
      chunk = {
        enable = true,
        delay = 0,
        style = {
          { fg = "#806d9c" },
        },
        chars = {
          horizontal_line = "─",
          vertical_line = "│",
          left_top = "╭",
          left_bottom = "╰",
          right_arrow = ">",
        },
      },
      indent = {
        enable = true,
        chars = {
          "│",
          "¦",
          "┆",
          "┊",
        },
        style = {
          { fg = vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID("Whitespace")), "fg", "gui") },
        },
      },
      line_num = {
        enable = false,
      },
    })
  end
}
