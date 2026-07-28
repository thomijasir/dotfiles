local pack = require("utils.pack")

pack.add({
  {
    src = "https://github.com/kdheepak/lazygit.nvim",
  },
})

-- make lazygit full screen
vim.g.lazygit_floating_window_scaling_factor = 1.0

-- Use the shared LazyGit config by default, then override its editor so files
-- selected from :LazyGit open in this Neovim instance.
local lazygit_config_dir = vim.fn.systemlist({ "lazygit", "--print-config-dir" })[1]
vim.g.lazygit_use_custom_config_file_path = 1
vim.g.lazygit_config_file_path = {
  lazygit_config_dir .. "/config.yml",
  vim.fn.stdpath("config") .. "/lazygit.yml",
}

vim.keymap.set("n", ";g", "<cmd>LazyGit<cr>", {
  desc = "Open LazyGit",
  silent = true,
})
