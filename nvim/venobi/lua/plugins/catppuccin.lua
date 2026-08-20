local pack = require("utils.pack")
pack.add({ { src = "https://github.com/catppuccin/nvim", version = "stable", name = "catppuccin" } })
-- Activate Theme --
vim.cmd.colorscheme("catppuccin-macchiato")
