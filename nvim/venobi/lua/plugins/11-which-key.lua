local pack = require("utils.pack")
pack.add {{ src = "https://github.com/folke/which-key.nvim" }}

vim.opt.timeout = true
vim.opt.timeoutlen = 500

local which_key = require("which-key")

which_key.setup({
  delay = 50, 
  preset = "helix", -- Classic clean layout
})

which_key.add({
  { ";", group = "Development tools" },
})
