return {
  -- Spelunker https://github.com/kamykn/spelunker.vim
  "kamykn/spelunker.vim",
  event = "VeryLazy",
  config = function()
    vim.g.spelunker_check_type = 2 -- Check on CursorHold
    vim.g.spelunker_highlight_type = 1 -- Underline style
  end,
}
