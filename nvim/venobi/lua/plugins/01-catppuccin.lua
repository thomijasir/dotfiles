local pack = require("utils.pack")
pack.add({ { src = "https://github.com/catppuccin/nvim", name = "catppuccin" } })
-- set undercurl
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    vim.api.nvim_set_hl(0, "DiagnosticUnderlineError", {
      undercurl = true,
      sp = "#ff5555",
    })
    vim.api.nvim_set_hl(0, "DiagnosticUnderlineWarn", {
      undercurl = true,
      sp = "#ffaa00",
    })
    vim.api.nvim_set_hl(0, "DiagnosticUnderlineInfo", {
      undercurl = true,
      sp = "#00afff",
    })
    vim.api.nvim_set_hl(0, "DiagnosticUnderlineHint", {
      undercurl = true,
      sp = "#00ff88",
    })
  end,
})
vim.cmd.colorscheme("catppuccin-macchiato")
