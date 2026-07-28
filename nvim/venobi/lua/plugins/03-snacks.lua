local pack = require("utils.pack")

pack.add({
  {
    src = "https://github.com/folke/snacks.nvim",
  },
})

local lazygit_config_dir = vim.fn.systemlist({ "lazygit", "--print-config-dir" })[1]
local custom_config_path = vim.fn.stdpath("config") .. "/lazygit.yml"
local map = vim.keymap.set

require("snacks").setup({
  image = { enabled = true }, -- Enables high-res image previews for Ghostty
  bufdelete = { enabled = true },
  indent = { enabled = true },
  lazygit = {
    enabled = true,
    -- Passes custom configuration files to LazyGit
    args = {
      "--use-config-file",
      lazygit_config_dir .. "/config.yml," .. custom_config_path,
    },
  },
})

map("n", ";g", function()
  Snacks.lazygit({
    win = {
      width = 0,
      height = 0,
    },
  })
end, {
  desc = "Open LazyGit",
  silent = true,
})

map("n", "<leader>bd", function()
  Snacks.bufdelete()
end, { desc = "Close buffer" })

map("n", "<leader>bo", function()
  Snacks.bufdelete.other()
end, { desc = "Close other buffer" })
