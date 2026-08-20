local pack = require("utils.pack")

pack.add({
  {
    src = "https://github.com/MagicDuck/grug-far.nvim",
  },
}, {
  lazy = true,
})

vim.keymap.set("n", "<leader>sr", function()
  vim.cmd.packadd("grug-far.nvim")
  require("grug-far").open()
end, {
  desc = "Search and replace",
})
