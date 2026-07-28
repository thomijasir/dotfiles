local pack = require("utils.pack")

pack.add({
  {
    src = "https://github.com/folke/snacks.nvim",
  },
})

local custom_config_path = vim.fn.stdpath("config") .. "/lazygit.yml"
local map = vim.keymap.set

require("snacks").setup({
  -- Enables high-res image previews for Ghostty (also powers fzf-lua image previews).
  -- `doc` is disabled so it does not double-render inline markdown images that
  -- image.nvim already handles; fzf-lua previews are unaffected (they use the
  -- image module directly, not `doc`).
  image = {
    enabled = true,
    doc = { enabled = false },
  },
  bufdelete = { enabled = true },
  indent = { enabled = true },
  lazygit = {
    enabled = true,
  },
})

-- Resolve LazyGit's config directory lazily (only when `;g` is pressed) and
-- cache the result, so startup never shells out to `lazygit`.
local lazygit_args ---@type string[]?

local function get_lazygit_args()
  if lazygit_args then
    return lazygit_args
  end

  local config_dir = vim.fn.systemlist({ "lazygit", "--print-config-dir" })[1] or ""

  if vim.v.shell_error ~= 0 or config_dir == "" then
    return nil
  end

  lazygit_args = {
    "--use-config-file",
    config_dir .. "/config.yml," .. custom_config_path,
  }
  return lazygit_args
end

map("n", ";g", function()
  if vim.fn.executable("lazygit") == 0 then
    vim.notify("lazygit is not installed", vim.log.levels.WARN)
    return
  end

  Snacks.lazygit({
    win = {
      width = 0,
      height = 0,
    },
    args = get_lazygit_args(),
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
