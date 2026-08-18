local pack = require("utils.pack")

pack.add({
  { src = "https://github.com/mason-org/mason.nvim" },
  { src = "https://github.com/mason-org/mason-lspconfig.nvim" },
  { src = "https://github.com/neovim/nvim-lspconfig" },
  { src = "https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim" },
})

require("mason").setup()

local servers = {
  "astro",
  "lua_ls",
  "vtsls",
  "vue_ls",
  "tailwindcss",
  "html",
  "cssls",
  "jsonls",
  "yamlls",
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

local eslint_on_attach = vim.lsp.config.eslint.on_attach
local eslint_fix_group = vim.api.nvim_create_augroup("UserEslintFixAll", { clear = true })

vim.lsp.config("eslint", {
  on_attach = function(client, bufnr)
    if eslint_on_attach then
      eslint_on_attach(client, bufnr)
    end

    vim.api.nvim_clear_autocmds({ group = eslint_fix_group, buffer = bufnr })
    vim.api.nvim_create_autocmd("BufWritePre", {
      group = eslint_fix_group,
      buffer = bufnr,
      command = "LspEslintFixAll",
      desc = "Apply all ESLint fixes before saving",
    })
  end,
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
    "pgformat", -- SQL Formatter
    "taplo", -- TOML Formatter
  }),
  auto_update = false,
  run_on_start = true,
  start_delay = 1000,
  debounce_hours = 24,
})
