return {
  'm4xshen/hardtime.nvim',
  dependencies = { 'MunifTanjim/nui.nvim', 'nvim-lua/plenary.nvim' },
  opts = {
    max_count = 3, -- Block after 2 repeated keys
    disabled_keys = {
      ['<Up>'] = {},
      ['<Down>'] = {},
      ['<Left>'] = {},
      ['<Right>'] = {},
    },
    restricted_keys = {
      ['h'] = { 'n', 'x' },
      ['j'] = { 'n', 'x' },
      ['k'] = { 'n', 'x' },
      ['l'] = { 'n', 'x' },
      ['w'] = { 'n', 'x' },
      ['b'] = { 'n', 'x' },
      ['e'] = { 'n', 'x' },
      ['W'] = { 'n', 'x' },
      ['B'] = { 'n', 'x' },
      ['E'] = { 'n', 'x' },
    },
  },
}

