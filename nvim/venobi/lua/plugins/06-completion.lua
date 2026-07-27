local pack = require("utils.pack")
pack.add {
  {
   src = "https://github.com/Saghen/blink.cmp",
   version = vim.version.range("1.*"),
  }
}
  
require("blink.cmp").setup({
  keymap = {
    preset = "default",
  },
  cmdline = {
    keymap = {
      preset = "inherit",
    },
    completion = {
      menu = {
        auto_show = true,
      },
    },
  },
  completion = {
    documentation = {
      auto_show = true,
      auto_show_delay_ms = 300,
    },
  },
  sources = {
    default = {
      "lsp",
      "path",
      "snippets",
      "buffer",
    },
  },
  fuzzy = {
    implementation = "prefer_rust_with_warning",
  },
})
