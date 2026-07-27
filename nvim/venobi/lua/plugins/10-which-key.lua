local pack = require("utils.pack")
pack.add {{ src = "https://github.com/folke/which-key.nvim" }}

vim.opt.timeout = true
vim.opt.timeoutlen = 200

require("which-key").setup({
  delay = 50, 
  preset = "helix", -- Classic clean layout
})
