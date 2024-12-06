return {
  "phaazon/hop.nvim",
  branch = "v2",
  config = function()
    local hop = require("hop")
    hop.setup({})

    -- hop highlights
    vim.keymap.set("n", "kl", function()
      require("hop").hint_words()
    end, { desc = "Hop to word" })
  end,
}
