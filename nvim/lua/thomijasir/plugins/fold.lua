return {
  {
    -- Universal Fold
    "kevinhwang91/nvim-ufo",
    dependencies = { "kevinhwang91/promise-async" },
    event = "VeryLazy",
    config = function()
      -- Configure UFO
      require("ufo").setup({
        provider_selector = function(bufnr, filetype, buftype)
          return { "treesitter", "indent" }
        end,
      })

      -- Key mappings
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
