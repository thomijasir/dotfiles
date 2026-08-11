local pack = require("utils.pack")
pack.add({ { src = "https://github.com/stevearc/conform.nvim" } })

local conform = require("conform")

conform.setup({
  formatters_by_ft = {
    astro = { "prettierd" },
    lua = { "stylua" },

    javascript = {
      "prettierd",
    },

    typescript = {
      "prettierd",
    },

    javascriptreact = {
      "prettierd",
    },

    typescriptreact = {
      "prettierd",
    },

    vue = {
      "prettierd",
    },

    json = {
      "prettierd",
    },

    css = {
      "prettierd",
    },

    html = {
      "prettierd",
    },

    markdown = {
      "prettierd",
    },

    yaml = {
      "prettierd",
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
