return {
  "supermaven-inc/supermaven-nvim",
  -- event = { "BufRead", "BufNewFile" },
  lazy = true, -- Only load when explicitly required
  event = "VeryLazy", -- Load after everything else (Lazy.nvim's special event)
  config = function()
    require("supermaven-nvim").setup({})
  end,
}
