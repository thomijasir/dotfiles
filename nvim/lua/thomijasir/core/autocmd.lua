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

-- Mouse control
function ToggleMouse()
  if vim.o.mouse == "a" then
    vim.o.mouse = ""
    print("Mouse disabled")
  else
    vim.o.mouse = "a"
    print("Mouse enabled")
  end
end

-- disable mouse as default
-- vim.o.mouse = ""
-- Optional: Create a command to call the function
vim.api.nvim_create_user_command("ToggleMouse", ToggleMouse, {})
-- Optional: Create a keymapping (e.g., <leader>m)
vim.keymap.set("n", "<leader>i", ToggleMouse, { desc = "Toggle mouse", noremap = true, silent = false })

-- vim.cmd([[highlight MatchParen cterm=bold gui=bold]])
