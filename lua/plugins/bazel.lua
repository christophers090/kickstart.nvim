-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return {
  {
    'alexander-born/bazel.nvim',
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'nvim-lua/plenary.nvim',
    },
    config = function()
      -- Configuration is optional, plugin works with defaults
      -- To use a different executable (like blaze), set:
      -- vim.g.bazel_cmd = "blaze"
    end,
  },
}
