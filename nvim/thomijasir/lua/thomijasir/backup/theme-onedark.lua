return {
  "navarasu/onedark.nvim",
  lazy = false, -- make sure we load this during startup if it is your main colorscheme
  priority = 1001, -- make sure to load this before all the other start plugins
  config = function()
    local onedark = require("onedark")
    onedark.setup({
      style = "dark",
    })
    onedark.load()
  end,
}
