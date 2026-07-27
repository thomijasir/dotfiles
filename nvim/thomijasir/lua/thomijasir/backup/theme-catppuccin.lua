return {
  "catppuccin/nvim",
  name = "catppuccin",
  lazy = false, -- make sure we load this during startup if it is your main colorscheme
  priority = 1001, -- make sure to load this before all the other start plugins
  config = function()
    local catppuccin = require("catppuccin")
    catppuccin.setup({
      flavour = "mocha", -- flavours: "latte", "frappe", "macchiato", "mocha"
    })
    vim.cmd.colorscheme("catppuccin")
  end,
}
