local pack = require("utils.pack")
pack.add({ { src = "https://github.com/folke/which-key.nvim" } })

vim.opt.timeout = true
vim.opt.timeoutlen = 500

local which_key = require("which-key")

which_key.setup({
  delay = 50,
  preset = "helix", -- Classic clean layout
})

which_key.add({
  { ";", group = "Development tools" },
  { "<leader>b", group = "Buffer" },
  { "<leader>c", group = "Code" },
  { "<leader>F", group = "Find" },
  { "<leader>g", group = "Git" },
  { "<leader>h", group = "Git hunks" },
  { "<leader>m", group = "Multicursor" },
  { "<leader>s", group = "Search" },
  { "<leader>t", group = "Tabs" },
  { "<leader>w", group = "Windows" },
  { "<leader>x", group = "Trouble" },
})
