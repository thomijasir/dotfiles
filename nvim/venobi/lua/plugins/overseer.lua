local pack = require("utils.pack")

pack.add({
  {
    src = "https://github.com/stevearc/overseer.nvim",
  },
}, {
  lazy = true,
})

local loaded = false

local function load_overseer()
  if loaded then
    return
  end
  vim.cmd.packadd("overseer.nvim")
  require("overseer").setup({})
  loaded = true
end

local function command(name)
  return function()
    load_overseer()
    vim.cmd(name)
  end
end

local map = vim.keymap.set

map("n", "<leader>or", command("OverseerRun"), {
  desc = "Run task",
})

map("n", "<leader>ot", command("OverseerToggle"), {
  desc = "Toggle task list",
})

map("n", "<leader>ol", command("OverseerRestartLast"), {
  desc = "Restart last task",
})
