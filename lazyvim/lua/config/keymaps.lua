-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
local map = vim.keymap.set
local opts = { noremap = true, silent = true }
-- Resize Window
map("n", "<A-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase window width" })
map("n", "<A-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease window width" })
map("n", "<A-Up>", "<cmd>resize +2<cr>", { desc = "Increase window height" })
map("n", "<A-Down>", "<cmd>resize -2<cr>", { desc = "Decrease window height" })

-- Select all
map("n", "<C-a>", "ggVG", { desc = "Select all" })

-- Move lines up/down in visual mode
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move line down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move line up" })

-- Delete single character without copying into register
map("n", "x", '"_x', opts)

-- Stay in indent mode
map("v", "<", "<gv", opts)
map("v", ">", ">gv", opts)

-- Keep last yanked when pasting
map("v", "p", '"_dP', opts)

-- Clear Selection after highlights
map("n", "<leader>cx", ":nohl<CR>", { desc = "Clear highlights" })

-- -- Mouse control with visual feedback
local function toggle_mouse()
  if vim.o.mouse == "a" then
    vim.o.mouse = ""
    vim.notify("Mouse disabled", vim.log.levels.INFO)
  else
    vim.o.mouse = "a"
    vim.notify("Mouse enabled", vim.log.levels.INFO)
  end
end

-- Set default mouse state (disabled)
vim.o.mouse = ""

-- Create user command
vim.api.nvim_create_user_command("ToggleMouse", toggle_mouse, {
  desc = "Toggle mouse support on/off",
})

--  keymap
map("n", "<leader>wi", toggle_mouse, {
  desc = "Toggle mouse",
  noremap = true,
  silent = true, -- Silent since vim.notify() handles feedback
})
