return {
  "jiaoshijie/undotree",
  dependencies = "nvim-lua/plenary.nvim",
  lazy = true,
  opts = {
    position = "right",
    float_diff = "false",
    window = {
      winblend = 0,
    },
  },
  keys = {
    { "<leader>u", "<cmd>lua require('undotree').toggle()<cr>", desc = "UndoTree" },
  },
}
