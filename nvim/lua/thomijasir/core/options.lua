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
opt.splitbelow = true -- Split horizontal window to the bottmo

-- Turn off swap file
opt.swapfile = false

-- Folding
opt.foldcolumn = "1"
opt.foldlevel = 99
opt.foldenable = true

-- Scroll control
opt.scrolloff = 10

-- Colors
opt.termguicolors = true
opt.signcolumn = "yes"
-- opt.showmatch = true

-- Spelling settings
-- opt.spell = true
-- opt.spelllang = "en,en_gb"
-- opt.spelloptions = "camel"
-- change color of spelling mistake
-- vim.cmd("highlight SpellBad ctermbg=white guibg=white")
-- vim.cmd("highlight SpellCap ctermbg=blue guibg=blue")
-- vim.cmd("highlight SpellRare ctermbg=magenta guibg=magenta")
-- vim.cmd("highlight SpellLocal ctermbg=cyan guibg=cyan")
