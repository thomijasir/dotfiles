return {
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      linters_by_ft = {
        javascript = { "eslint_d" },
        typescript = { "eslint_d" },
        javascriptreact = { "eslint_d" },
        typescriptreact = { "eslint_d" },
        svelte = { "eslint_d" },
      },
    },
    config = function(_, opts)
      local lint = require("lint")
      local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
      lint.linters_by_ft = opts.linters_by_ft
      local eslint = lint.linters.eslint_d
      eslint.args = {
        "--format",
        "json",
        "--stdin",
        "--stdin-filename",
        function()
          return vim.api.nvim_buf_get_nme(0)
        end,
      }

      vim.api.nvim_create_autocmd({ "BufWritePost", "BufEnter", "InsertLeave" }, {
        group = lint_augroup,
        callback = function()
          lint.try_lint(nil)
        end,
      })

      vim.keymap.set({ "n", "v" }, "<leader>fl", function()
        lint.try_lint()
      end, { desc = "Lint file" })
    end,
  },
  -- {
  --   "jose-elias-alvarez/null-ls.nvim",
  --   config = function()
  --     local null_ls = require("null-ls")
  --
  --     -- Check if an ESLint config file exists
  --     local eslint_config_exists = vim.fn.glob(".eslintrc*") ~= ""
  --
  --     -- Define sources
  --     local sources = {}
  --
  --     if eslint_config_exists then
  --       table.insert(sources, null_ls.builtins.diagnostics.eslint_d)
  --       table.insert(sources, null_ls.builtins.formatting.eslint_d)
  --       -- vim.notify("ESLint enabled: Configuration file found.", vim.log.levels.INFO, { timeout = 1000 })
  --     else
  --       -- vim.notify("ESLint disabled: No configuration file found.", vim.log.levels.INFO, { timeout = 1000 })
  --     end
  --
  --     -- Setup null-ls with the sources
  --     null_ls.setup({
  --       sources = sources,
  --       debug = false, -- Enable this if you want to debug null-ls behavior
  --     })
  --   end,
  -- },
}
