return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  init = function()
    vim.o.timeout = true
    vim.o.timeoutlen = 500
  end,
  opts = {
    -- your configuration comes here
    -- or leave it empty to use the default settings
    -- refer to the configuration section below
    preset = "helix",
    spec = {
      {
        "<leader>d",
        group = "Diffview",
        icon = "",
      },
      {
        "<leader>g",
        group = "Git tools",
      },
      {
        "<leader>s",
        group = "Screen window",
      },
      {
        "<leader>e",
        group = "File explorer",
      },
      {
        "<leader>f",
        group = "Finder tools",
      },
      {
        "<leader>x",
        group = "Troubeshooter",
        icon = "",
      },
      {
        "<leader>?",
        group = "Help",
        icon = "",
      },
      {
        "<leader>u",
        group = "Undo history",
        icon = "",
      },
      {
        "<leader>m",
        group = "Formatter",
        icon = "",
      },
      {
        "<leader>w",
        group = "Window session",
      },
      {
        "<leader>h",
        group = "Bookmarks",
        icon = "",
      },
    },
  },
  keys = {
    {
      "<leader>?",
      function()
        require("which-key").show({ global = false })
      end,
      desc = "Help",
    },
  },
}
