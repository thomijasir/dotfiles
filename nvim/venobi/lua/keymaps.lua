-- set default leader key
vim.g.mapleader = " " -- space leader key
vim.g.maplocalleader = "\\"
-- Disable Nvim Tree Explorer
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
-- vim.cmd("let g:netrw_liststyle = 3") -- active this for nvim explorer tree

local map = vim.keymap.set -- for conciseness
local opts = { noremap = true, silent = true }

-- Development tools
local function wezterm_command(command, with_file, success_message)
  return function()
    local args = { "vim-wezterm.sh", command }
    local job_opts = { detach = true }

    if with_file then
      local current_file = vim.api.nvim_buf_get_name(0)
      if current_file == "" then
        vim.notify("Current buffer has no file", vim.log.levels.WARN)
        return
      end
      table.insert(args, current_file)
    end

    if success_message then
      job_opts.on_exit = function(_, exit_code)
        if exit_code == 0 then
          vim.schedule(function()
            vim.notify(success_message, vim.log.levels.INFO)
          end)
        end
      end
    end

    if vim.fn.jobstart(args, job_opts) <= 0 then
      vim.notify("Failed to run vim-wezterm.sh " .. command, vim.log.levels.ERROR)
    end
  end
end

-- keymap.set("i", "jk", "<ESC>", { desc = "Exit insert mode with jk" })
-- map("n", "<leader>cx", ":nohl<CR>", { desc = "Clear" })
map("n", "<Esc>", "<cmd>nohlsearch<CR>", {
  silent = true,
  desc = "Clear search highlight",
})

map("n", ";t", wezterm_command("open_terminal_bottom"), { desc = "Open terminal", silent = true })
map("n", ";c", wezterm_command("open_in_vscode"), { desc = "Open VSCode", silent = true })
map("n", ";o", wezterm_command("reveal_current_folder", true), { desc = "Reveal current folder", silent = true })
map("n", ";y", wezterm_command("copy_filename", true, "Filename copied"), { desc = "Copy filename", silent = true })
map(
  "n",
  ";Y",
  wezterm_command("copy_abs_path", true, "Absolute path copied"),
  { desc = "Copy absolute path", silent = true }
)

-- increment/decrement numbers
-- map("n", "<leader>+", "<C-a>", { desc = "Increment number" }) -- increment
-- map("n", "<leader>-", "<C-x>", { desc = "Decrement number" }) -- decrement

-- Scrolling
map("n", "<C-u>", "<C-u>zz", opts) -- scroll up
map("n", "<C-d>", "<C-d>zz", opts) -- scroll down

-- window management
map("n", "<leader>wv", "<C-w>v", { desc = "Split vertically" }) -- split window vertically
map("n", "<leader>wh", "<C-w>s", { desc = "Split horizontally" }) -- split window horizontally
map("n", "<leader>we", "<C-w>=", { desc = "Window equal size" }) -- make split windows equal width & height
map("n", "<leader>wq", "<cmd>close<CR>", { desc = "Close split" }) -- close current split window
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
