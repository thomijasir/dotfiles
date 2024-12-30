return {
  event = { "BufReadPre", "BufNewFile" },
  "nvim-pack/nvim-spectre",
  dependencies = { "nvim-lua/plenary.nvim" }, -- Dependency for Spectre
  config = function()
    require("spectre").setup({
      color_devicons = true, -- Enable filetype icons
      highlight = {
        ui = "String", -- Highlight group for the UI
        search = "DiffChange", -- Highlight group for search matches
        replace = "DiffDelete", -- Highlight group for replacements
      },
    })
    -- Keymaps
    vim.keymap.set("n", "<leader>r", "<cmd>lua require('spectre').open()<CR>", { desc = "Refactor" })
  end,
}
