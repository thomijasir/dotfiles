local pack = require("utils.pack")
pack.add {{ src = "https://github.com/folke/which-key.nvim" }}

require("which-key").setup({
  preset = "helix", -- Classic clean layout
})
