local pack = require("utils.pack")

pack.add({
  {
    src = "https://github.com/dlyongemallo/diffview-plus.nvim",
  },
}, {
  lazy = true,
})

local loaded = false

local function load_diffview()
  if loaded then
    return
  end

  vim.cmd.packadd("diffview-plus.nvim")
  require("diffview").setup({})
  loaded = true
end

vim.keymap.set("n", "<leader>gv", function()
  load_diffview()
  vim.cmd("DiffviewOpen")
end, {
  desc = "Open Git diff view",
})
