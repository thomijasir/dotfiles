local pack = require("utils.pack")
pack.add({
  {
    src = "https://github.com/nvim-treesitter/nvim-treesitter",
    version = "main",
  },
  {
    src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects",
    version = "main",
  },
  {
    src = "https://github.com/windwp/nvim-ts-autotag",
  },
})

local treesitter = require("nvim-treesitter")

treesitter.setup({
  install_dir = vim.fn.stdpath("data") .. "/site",
})

local parsers = {
  "astro",
  "bash",
  "css",
  "dockerfile",
  "html",
  "javascript",
  "json",
  "json5",
  "lua",
  "markdown",
  "markdown_inline",
  "python",
  "query",
  "rust",
  "sql",
  "toml",
  "tsx",
  "typescript",
  "vim",
  "vimdoc",
  "vue",
  "yaml",
}

vim.schedule(function()
  treesitter.install(parsers)
end)

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("user_treesitter_start", { clear = true }),

  callback = function(event)
    local has_parser = pcall(vim.treesitter.start, event.buf)
    if not has_parser then
      return
    end

    vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
    vim.wo.foldmethod = "expr"
  end,
})

require("nvim-ts-autotag").setup({
  opts = {
    enable_close = true,
    enable_rename = true,
    enable_close_on_slash = false,
  },
})

require("nvim-treesitter-textobjects").setup({
  select = {
    lookahead = true,
    selection_modes = {
      ["@parameter.outer"] = "v",
      ["@function.outer"] = "V",
      ["@class.outer"] = "V",
    },
  },
  move = {
    set_jumps = true,
  },
})

local map = vim.keymap.set
local select = require("nvim-treesitter-textobjects.select")
local move = require("nvim-treesitter-textobjects.move")

local function select_textobject(lhs, capture, desc)
  map({ "x", "o" }, lhs, function()
    select.select_textobject(capture, "textobjects")
  end, { desc = desc })
end

select_textobject("af", "@function.outer", "Around function")
select_textobject("if", "@function.inner", "Inside function")
select_textobject("ac", "@class.outer", "Around class")
select_textobject("ic", "@class.inner", "Inside class")
select_textobject("aa", "@parameter.outer", "Around argument")
select_textobject("ia", "@parameter.inner", "Inside argument")

map({ "n", "x", "o" }, "]m", function()
  move.goto_next_start("@function.outer", "textobjects")
end, { desc = "Next function" })

map({ "n", "x", "o" }, "[m", function()
  move.goto_previous_start("@function.outer", "textobjects")
end, { desc = "Previous function" })

map({ "n", "x", "o" }, "]]", function()
  move.goto_next_start("@class.outer", "textobjects")
end, { desc = "Next class" })

map({ "n", "x", "o" }, "[[", function()
  move.goto_previous_start("@class.outer", "textobjects")
end, { desc = "Previous class" })
