local pack = require("utils.pack")

pack.add({
  {
    src = "https://github.com/esmuellert/codediff.nvim",
  },
}, {
  lazy = true,
})

local loaded = false

local function load_codediff()
  if loaded then
    return
  end
  vim.cmd.packadd("codediff.nvim")
  require("codediff").setup({})
  loaded = true
end

local function command(args)
  return function()
    load_codediff()
    vim.cmd(args == "" and "CodeDiff" or "CodeDiff " .. args)
  end
end

local map = vim.keymap.set

map("n", "<leader>gv", command(""), {
  desc = "Open CodeDiff view",
})

map("n", "<leader>gH", command("history %"), {
  desc = "Current file Git history",
})
