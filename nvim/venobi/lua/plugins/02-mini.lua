local pack = require("utils.pack")
pack.add {
  {
    src = "https://github.com/nvim-mini/mini.nvim",
    version = "stable"
  }
}

require("mini.pairs").setup()
require("mini.surround").setup()
require("mini.icons").setup()
require("mini.statusline").setup()
require("mini.starter").setup()
require("mini.files").setup({
  options = {
    use_as_default_explorer = true,
  },

  windows = {
    preview = true,
    width_focus = 30,
    width_nofocus = 15,
    width_preview = 50,
  },
})

local jump2d = require("mini.jump2d")

jump2d.setup({
  labels = "asdfghjklqwertyuiopzxcvbnm",

  view = {
    dim = true,
    n_steps_ahead = 2,
  },

  mappings = {
    start_jumping = "",
  },

  silent = true,
})


local map = vim.keymap.set

map(
  { "n", "x", "o" },
  "gw",
  function()
    jump2d.start(
      jump2d.builtin_opts.word_start
    )
  end,
  {
    desc = "Jump to visible word",
  }
)


map("n", "<leader>e", function()
  MiniFiles.open(vim.fn.getcwd())
end, {
  desc = "Open file explorer",
})
