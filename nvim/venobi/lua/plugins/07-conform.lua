local pack = require("utils.pack")
pack.add {{ src = "https://github.com/stevearc/conform.nvim" }}

require("conform").setup({
  formatters_by_ft = {
    lua = { "stylua" },

    javascript = {
      "prettierd",
      "prettier",
      stop_after_first = true,
    },

    typescript = {
      "prettierd",
      "prettier",
      stop_after_first = true,
    },

    javascriptreact = {
      "prettierd",
      "prettier",
      stop_after_first = true,
    },

    typescriptreact = {
      "prettierd",
      "prettier",
      stop_after_first = true,
    },

    vue = {
      "prettierd",
      "prettier",
      stop_after_first = true,
    },

    json = {
      "prettierd",
      "prettier",
      stop_after_first = true,
    },

    css = {
      "prettierd",
      "prettier",
      stop_after_first = true,
    },

    html = {
      "prettierd",
      "prettier",
      stop_after_first = true,
    },

    rust = {
      "rustfmt",
      lsp_format = "fallback",
    },

    python = {
      "ruff_format",
    },
  },

  format_on_save = {
    timeout_ms = 1000,
    lsp_format = "fallback",
  },
})

vim.keymap.set({ "n", "v" }, "<leader>cf", function()
  conform.format({
    async = true,
    lsp_format = "fallback",
  })
end, {
  desc = "Format file",
})
