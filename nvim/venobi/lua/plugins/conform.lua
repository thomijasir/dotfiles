local pack = require("utils.pack")
pack.add({ { src = "https://github.com/stevearc/conform.nvim", version = "stable" } })

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

    jsonc = {
      "prettierd",
    },

    json5 = {
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
    },

    python = {
      "ruff_organize_imports",
      "ruff_format",
    },

    sql = {
      "pg_format",
    },

    sh = {
      "shfmt",
    },

    bash = {
      "shfmt",
    },

    zsh = {
      "shfmt",
    },

    toml = {
      "taplo",
    },
  },

  format_on_save = function(bufnr)
    if vim.b[bufnr].skip_format_once then
      vim.b[bufnr].skip_format_once = nil
      return
    end

    return {
      timeout_ms = 1000,
      lsp_format = "fallback",
    }
  end,
})

-- Keep PostgreSQL and PL/pgSQL formatting consistent and readable.
conform.formatters.pg_format = {
  prepend_args = {
    "--no-space-function",
    "--keyword-case",
    "2",
    "--function-case",
    "0",
    "--type-case",
    "1",
    "--spaces",
    "4",
    "--wrap-limit",
    "100",
    "--keep-newline",
    "--no-extra-line",
    "--redundant-parenthesis",
  },
}

vim.keymap.set({ "n", "v" }, "<leader>cf", function()
  conform.format({
    async = true,
    lsp_format = "fallback",
  })
end, {
  desc = "Format file",
})
