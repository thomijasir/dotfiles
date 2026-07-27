local pack = require("utils.pack")

pack.add({
  {
    src = "https://github.com/folke/lazydev.nvim",
  },
})

require("lazydev").setup({
  library = {
    {
      path = "${3rd}/luv/library",
      words = { "vim%.uv" },
    },
  },
})
