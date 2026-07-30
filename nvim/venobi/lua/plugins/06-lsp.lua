local pack = require("utils.pack")

pack.add({
  { src = "https://github.com/mason-org/mason.nvim" },
  { src = "https://github.com/mason-org/mason-lspconfig.nvim" },
  { src = "https://github.com/neovim/nvim-lspconfig" },
  { src = "https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim" },
})

require("mason").setup()

local servers = {
  "lua_ls",
  "vtsls",
  "vue_ls",
  "tailwindcss",
  "basedpyright",
  "ruff",
  "rust_analyzer",
  "eslint",
  "typos_lsp",
}

local vue_language_server_path = vim.fs.joinpath(
  vim.fn.stdpath("data"),
  "mason",
  "packages",
  "vue-language-server",
  "node_modules",
  "@vue",
  "language-server"
)

vim.lsp.config("vtsls", {
  filetypes = {
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
    "vue",
  },
  settings = {
    vtsls = {
      tsserver = {
        globalPlugins = {
          {
            name = "@vue/typescript-plugin",
            location = vue_language_server_path,
            languages = { "vue" },
            configNamespace = "typescript",
          },
        },
      },
    },
  },
})

vim.lsp.config("basedpyright", {
  settings = {
    basedpyright = {
      analysis = {
        diagnosticMode = "openFilesOnly",
        typeCheckingMode = "standard",
        -- Delegate lint-style diagnostics to ruff so the two servers don't
        -- report the same problems (unused imports/variables, etc.).
        -- basedpyright focuses on type checking; ruff handles linting.
        diagnosticSeverityOverrides = {
          reportUnusedImport = "none",
          reportUnusedVariable = "none",
          reportUnusedFunction = "none",
          reportUnusedClass = "none",
          reportUnusedExpression = "none",
          reportDuplicateImport = "none",
        },
      },
    },
  },
})

vim.lsp.config("eslint", {
  settings = {
    format = false,
  },
})

vim.lsp.config("typos_lsp", {
  init_options = {
    diagnosticSeverity = "Hint",
  },
})

require("mason-lspconfig").setup({
  automatic_enable = servers,
})

require("mason-tool-installer").setup({
  ensure_installed = vim.list_extend(vim.deepcopy(servers), {
    "stylua",
    "prettierd",
  }),
  auto_update = false,
  run_on_start = true,
  start_delay = 1000,
  debounce_hours = 24,
})
