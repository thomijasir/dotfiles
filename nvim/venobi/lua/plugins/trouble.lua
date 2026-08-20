local pack = require("utils.pack")

pack.add({
  {
    src = "https://github.com/folke/trouble.nvim",
    version = "stable",
  },
})

require("trouble").setup({})

local map = vim.keymap.set

map("n", "<leader>xD", "<cmd>Trouble diagnostics toggle<CR>", {
  desc = "Diagnostics workspace",
})

map("n", "<leader>xd", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>", {
  desc = "Diagnostics document",
})

map("n", "<leader>xq", "<cmd>Trouble quickfix toggle<CR>", {
  desc = "Trouble quickfix list",
})

map("n", "<leader>xl", "<cmd>Trouble loclist toggle<CR>", {
  desc = "Trouble location list",
})

map("n", "<leader>xt", "<cmd>Trouble todo toggle<CR>", {
  desc = "Todos in trouble",
})
