local pack = require("utils.pack")

pack.add({
  {
    src = "https://github.com/nvim-lua/plenary.nvim",
  },
  {
    src = "https://github.com/folke/todo-comments.nvim",
  },
})

local todo_comments = require("todo-comments")

todo_comments.setup({})

vim.keymap.set("n", "]t", function()
  todo_comments.jump_next()
end, { desc = "Next TODO comment" })

vim.keymap.set("n", "[t", function()
  todo_comments.jump_prev()
end, { desc = "Previous TODO comment" })
