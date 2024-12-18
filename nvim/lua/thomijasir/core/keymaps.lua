vim.g.mapleader = " "

local keymap = vim.keymap -- for conciseness
local opts = { noremap = true, silent = true }
-- keymap.set("i", "jk", "<ESC>", { desc = "Exit insert mode with jk" })
keymap.set("n", "<leader>c", ":nohl<CR>", { desc = "Clear highlights" })

-- increment/decrement numbers
-- keymap.set("n", "<leader>+", "<C-a>", { desc = "Increment number" }) -- increment
-- keymap.set("n", "<leader>-", "<C-x>", { desc = "Decrement number" }) -- decrement

-- Scrolling
keymap.set("n", "<C-u>", "<C-u>zz", opts) -- scroll up
keymap.set("n", "<C-d>", "<C-d>zz", opts) -- scroll down

-- window management
keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" }) -- split window vertically
keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally" }) -- split window horizontally
keymap.set("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" }) -- make split windows equal width & height
keymap.set("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close current split" }) -- close current split window

keymap.set("n", "<leader>to", "<cmd>tabnew<CR>", { desc = "Open new tab" }) -- open new tab
keymap.set("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "Close current tab" }) -- close current tab
keymap.set("n", "<leader>tn", "<cmd>tabn<CR>", { desc = "Go to next tab" }) --  go to next tab
keymap.set("n", "<leader>tp", "<cmd>tabp<CR>", { desc = "Go to previous tab" }) --  go to previous tab
keymap.set("n", "<leader>tf", "<cmd>tabnew %<CR>", { desc = "Open current buffer in new tab" }) --  move current buffer to new tab

-- Save with Ctrl+S in normal and insert mode
keymap.set("n", "<C-s>", ":w<CR>", opts)
keymap.set("i", "<C-s>", "<Esc>:w<CR>", opts)

-- Select all
keymap.set("n", "<C-a>", "ggVG", opts)

-- Save without formatting
keymap.set("n", "<leader>W", ":noa w<CR>", { desc = "Save w/o formatting", silent = true })
-- keymap.set("i", "<leader>W", "<Esc>:noa w<CR>", { desc = "Save without formatting", silent = true })

-- quit file
keymap.set("n", "<C-q>", "<cmd> q <CR>", opts)

-- delete single character without copying into register
keymap.set("n", "x", '"_x', opts)

-- Stay in indent mode
keymap.set("v", "<", "<gv", opts)
keymap.set("v", ">", ">gv", opts)

-- Keep last yanked when pasting
keymap.set("v", "p", '"_dP', opts)

-- Navigate between splits
keymap.set("n", "<C-k>", ":wincmd k<CR>", opts)
keymap.set("n", "<C-j>", ":wincmd j<CR>", opts)
keymap.set("n", "<C-h>", ":wincmd h<CR>", opts)
keymap.set("n", "<C-l>", ":wincmd l<CR>", opts)

-- Resize with arrows
keymap.set("n", "<M-Up>", ":resize -2<CR>", opts)
keymap.set("n", "<M-Down>", ":resize +2<CR>", opts)
keymap.set("n", "<M-Left>", ":vertical resize -2<CR>", opts)
keymap.set("n", "<M-Right>", ":vertical resize +2<CR>", opts)

-- Move lines up/down in visual mode
keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move line down" })
keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move line up" })
