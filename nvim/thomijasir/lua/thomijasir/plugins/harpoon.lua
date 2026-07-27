return {
  "ThePrimeagen/harpoon",
  branch = "master",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  lazy = true,
  config = true,
  keys = {
    { "<leader>hm", "<cmd>lua require('harpoon.mark').add_file()<cr>", desc = "Harpoon markfile" },
    { "<leader>hx", "<cmd>lua require('harpoon.ui').nav_next()<cr>", desc = "Next harpoon mark" },
    { "<leader>hz", "<cmd>lua require('harpoon.ui').nav_prev()<cr>", desc = "Previous harpoon mark" },
    { "<leader>ha", "<cmd>lua require('harpoon.ui').toggle_quick_menu()<cr>", desc = "Show harpoon menu" },
  },
}
