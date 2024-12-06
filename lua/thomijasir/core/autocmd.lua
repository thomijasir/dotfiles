local group = vim.api.nvim_create_augroup("Custom Au Group", { clear = true })

-- vim.api.nvim_create_autocmd("InsertLeave", {
--   command = ":update",
--   group = group,
--   desc = "Save on InsertLeave"
-- })

vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight on yank",
  group = group,
  callback = function()
    vim.highlight.on_yank()
  end,
})

vim.api.nvim_create_autocmd("BufWinEnter", {
  pattern = { "*.md" },
  group = group,
  callback = function()
    vim.opt_local.wrap = true
  end,
})

-- show on finder
vim.api.nvim_create_user_command("Rfinder", function()
  local path = vim.api.nvim_buf_get_name(0)
  os.execute("open -R " .. path)
end, {})
