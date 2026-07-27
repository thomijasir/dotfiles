local pack = require("utils.pack")

pack.add({
  {
    src = "https://github.com/kdheepak/lazygit.nvim",
  },
})

-- make lazygit full screen
vim.g.lazygit_floating_window_scaling_factor = 1.0

vim.keymap.set("n", ";g", "<cmd>LazyGit<cr>", {
  desc = "Open LazyGit",
  silent = true,
})
