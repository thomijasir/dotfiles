return {
  {
    -- Universal Fold
    event = { "BufReadPre", "BufNewFile" },
    "kevinhwang91/nvim-ufo",
    dependencies = { "kevinhwang91/promise-async" },
    config = function()
      -- Configure UFO
      require("ufo").setup({
        provider_selector = function()
          return { "treesitter", "indent" }
        end,
      })

      local opts = { noremap = true, silent = true }
      -- Key mappings
      vim.keymap.set("n", "_", "za", opts)
      vim.keymap.set("n", "zR", function()
        require("ufo").openAllFolds()
      end, { desc = "Open all folds" })

      vim.keymap.set("n", "zM", function()
        require("ufo").closeAllFolds()
      end, { desc = "Close all folds" })
    end,
  },
  -- {
  --   -- Fold preview
  --   "anuvyklack/fold-preview.nvim",
  --   dependencies = "anuvyklack/keymap-amend.nvim",
  --   config = true,
  -- },
}
