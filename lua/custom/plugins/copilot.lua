return {
  'zbirenbaum/copilot.lua',
  cmd = 'Copilot', -- lazy-load when :Copilot* cmd is used
  build = ':Copilot auth', -- run once to open the browser login
  opts = {
    suggestion = { enabled = false }, -- Code Companion will handle completions
    panel = { enabled = false },
    filetypes = { ['*'] = true }, -- allow everywhere
  },
}
