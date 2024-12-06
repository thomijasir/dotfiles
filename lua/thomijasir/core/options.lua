vim.cmd("let g:netrw_liststyle = 3")

local opt = vim.opt

-- General
opt.title = true
opt.cmdheight = 0
opt.wrap = false

-- Number
opt.relativenumber = true
opt.number = true

-- Cursor
opt.cursorline = true
opt.cursorcolumn = true

-- Search settings
opt.ignorecase = true
opt.smartcase = true

-- Tabs & indentation
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.autoindent = true
opt.smartindent = true

-- Backspace
opt.backspace = "indent,eol,start"

-- Clipboard
opt.clipboard:append("unnamedplus")

-- Split windows
opt.splitright = true -- Split vertical window to the right
opt.splitbelow = true -- Split horizontal window to the bottom

-- Turn off swapfile
opt.swapfile = false

-- Folding
opt.foldcolumn = "1"
opt.foldlevel = 99
opt.foldenable = true
