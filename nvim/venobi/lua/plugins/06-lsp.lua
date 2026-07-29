local pack = require("utils.pack")

pack.add({
  { src = "https://github.com/mason-org/mason.nvim" },
  { src = "https://github.com/mason-org/mason-lspconfig.nvim" },
  { src = "https://github.com/neovim/nvim-lspconfig" },
  { src = "https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim" },
  { src = "https://github.com/chaneyzorn/spellwand.nvim" },
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

-- Expose Neovim's native spell checker as LSP diagnostics and code actions.
-- This keeps suggestions in sync with spelllang, spellfile, and `zg`/`z=`.
--
-- Performance tuning: on files full of non-dictionary tokens (e.g. .ghostty,
-- .dat, .mex) almost every word reads as "misspelled", so the defaults make
-- each refresh expensive. The knobs below keep spell on everywhere while
-- cutting the per-refresh cost:
--   - num_suggestions_in_diagnostics = 0: skip per-word `spellsuggest` calls
--     during the diagnostic scan (the biggest win). Suggestions are still
--     computed on demand via the code action (<leader>a).
--   - max_errors = 100: cap how many diagnostics are built/rendered per buffer
--     (the scan also stops early once the cap is reached).
--   - debounce_ms = 500: re-scan less often on normal-mode buffer changes.
-- spelling file located at ~/.local/share/nvim/site/spell/en.utf-8.add
-- sample link spell file
-- ln -sf ~/Workspace/dotfiles/nvim/venobi/spell/en.utf-8.add ~/.local/share/nvim/site/spell/en.utf-8.add
vim.lsp.config("spellwand", {
  settings = {
    spellwand = {
      num_suggestions_in_diagnostics = 0,
      num_suggestions_in_code_action = 5,
      max_errors = 100,
      debounce_ms = 500,
    },
  },
})
vim.lsp.enable("spellwand")

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
