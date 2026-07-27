return {
  "ggandor/leap.nvim",
  event = { "BufRead", "BufNewFile" },
  config = function()
    local leap = require("leap")
    leap.setup({
      case_sensitive = true,
    })
    -- DOCS: https://github.com/ggandor/leap.nvim/blob/main/doc/leap.txt
    -- Setting Highlights
    vim.api.nvim_set_hl(0, "LeapBackdrop", { fg = "#ffffff" }) -- Dim non-target text
    vim.api.nvim_set_hl(0, "LeapMatch", { fg = "#ffff00", bold = true, nocombine = true })
    vim.api.nvim_set_hl(0, "LeapLabel", { fg = "#ff0000", bold = true, underline = true })

    -- Setting Keymaps
    vim.keymap.set("n", "<leader><space>", "<Plug>(leap)", { noremap = true, silent = true, desc = "Hop to spot" })
  end,
}
