-- set default leader key
vim.g.mapleader = " " -- space leader key
vim.g.maplocalleader = "\\"
-- Disable Nvim Tree Explorer
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
-- vim.cmd("let g:netrw_liststyle = 3") -- active this for nvim explorer tree

local map = vim.keymap.set -- for conciseness
local opts = { noremap = true, silent = true }

-- keymap.set("i", "jk", "<ESC>", { desc = "Exit insert mode with jk" })
-- map("n", "<leader>cx", ":nohl<CR>", { desc = "Clear" })
map("n", "<Esc>", "<cmd>nohlsearch<CR>", {
  silent = true,
  desc = "Clear search highlight",
})

-- Open current working directory in VS Code
map("n", ";c", function()
  vim.fn.system("code .")
end, { desc = "Open VSCode", silent = true })

-- Open the current file's folder
map("n", ";o", function()
  vim.fn.system("open " .. vim.fn.shellescape(vim.fn.expand("%:p:h")))
end, { desc = "Open current file folder", silent = true })

-- Open Neovim's working directory
map("n", ";O", function()
  vim.fn.system("open " .. vim.fn.shellescape(vim.fn.getcwd()))
end, { desc = "Open workspace", silent = true }) -- Copy filename

-- Nvim Copy fn --
map("n", ";y", function()
  vim.fn.setreg("+", vim.fn.expand("%:t"))
  vim.notify("Filename copied")
end, { desc = "Filename copied", silent = true })

-- Copy relative file path
map("n", ";r", function()
  vim.fn.setreg("+", vim.fn.expand("%:."))
  vim.notify("Relative path copied")
end, { desc = "Relative path copied", silent = true })

-- Copy absolute file path
map("n", ";Y", function()
  vim.fn.setreg("+", vim.fn.expand("%:p"))
  vim.notify("Absolute path copied")
end, { desc = "Absolute path copied", silent = true })

-- Scrolling
map("n", "<C-u>", "<C-u>zz", opts) -- scroll up
map("n", "<C-d>", "<C-d>zz", opts) -- scroll down

-- window management
map("n", "<leader>wv", "<C-w>v", { desc = "Split vertically" }) -- split window vertically
map("n", "<leader>wh", "<C-w>s", { desc = "Split horizontally" }) -- split window horizontally
map("n", "<leader>we", "<C-w>=", { desc = "Window equal size" }) -- make split windows equal width & height
map("n", "<leader>q", "<cmd>close<CR>", { desc = "Close Window" }) -- close current split window
map("n", "<leader>ww", function()
  vim.wo.wrap = not vim.wo.wrap
end, { desc = "Toggle wrap" }) -- toggle wrap ons window

map("n", "<leader>to", "<cmd>tabnew<CR>", { desc = "Open new tab" }) -- open new tab
map("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "Close current tab" }) -- close current tab
map("n", "<leader>tn", "<cmd>tabn<CR>", { desc = "Go to next tab" }) --  go to next tab
map("n", "<leader>tp", "<cmd>tabp<CR>", { desc = "Go to previous tab" }) --  go to previous tab
map("n", "<leader>tf", "<cmd>tabnew %<CR>", { desc = "Open current buffer in new tab" }) --  move current buffer to new tab

-- Save with Ctrl+S without leaving insert mode. BufWritePre still runs, so
-- Conform's format-on-save is applied.
map({ "n", "i" }, "<C-s>", "<cmd>write<CR>", {
  desc = "Save file",
  silent = true,
})

map("n", "<leader>cW", "<cmd>noautocmd write<CR>", {
  desc = "Save without autocommands",
  silent = true,
})

-- Select all
map("n", "<C-a>", "ggVG", opts)

-- quit file
map("n", "<C-q>", "<cmd> q <CR>", opts)

-- delete single character without copying into register
map("n", "x", '"_x', opts)

-- Toggle comments
map("n", "<C-c>", "gcc", {
  desc = "Toggle comment on current line",
  remap = true,
})

map("x", "<C-c>", "gc", {
  desc = "Toggle comment on selection",
  remap = true,
})

-- Restart
map("n", "<leader>rs", "<cmd>restart<cr>", { desc = "Restart" })

-- Stay in indent mode
map("v", "<", "<gv", opts)
map("v", ">", ">gv", opts)

-- Keep last yanked when pasting
map("v", "p", '"_dP', opts)

-- Navigate between splits
map("n", "<C-k>", ":wincmd k<CR>", opts)
map("n", "<C-j>", ":wincmd j<CR>", opts)
map("n", "<C-h>", ":wincmd h<CR>", opts)
map("n", "<C-l>", ":wincmd l<CR>", opts)

-- Resize with arrows
map("n", "<M-Up>", ":resize -2<CR>", opts)
map("n", "<M-Down>", ":resize +2<CR>", opts)
map("n", "<M-Left>", ":vertical resize -2<CR>", opts)
map("n", "<M-Right>", ":vertical resize +2<CR>", opts)

-- Move lines up/down in visual mode
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move line down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move line up" })
