local pack = require("utils.pack")

pack.add({
  {
    src = "https://github.com/MagicDuck/grug-far.nvim",
  },
}, {
  lazy = true,
})

local loaded = false

local function check()
  if loaded then
    return
  end
  vim.cmd.packadd("grug-far.nvim")
  loaded = true
end

local map = vim.keymap.set

map("n", "<leader>sr", function()
  check()
  require("grug-far").open()
end, {
  desc = "Search and replace",
})
