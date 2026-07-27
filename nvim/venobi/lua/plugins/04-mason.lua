local pack = require("utils.pack")
pack.add {
  { src = "https://github.com/mason-org/mason.nvim" },
  { src = "https://github.com/mason-org/mason-lspconfig.nvim" },
}
require("mason").setup()
require("mason-lspconfig").setup()
