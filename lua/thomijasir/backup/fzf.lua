return {
  "ibhagwan/fzf-lua",
  lazy = true,
  event = "VeryLazy",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    "telescope",
    files = {
      -- cwd_prompt = false
      fd_opts = [[--color=never --type f --hidden --follow --exclude .git --exclude node_modules --exclude .DS_Store --exclude target --exclude release]],
      rg_opts = [[--color=never --files --hidden --follow -g "!{.git,node_modules,build,.DS_Store,src-tauri/target,src-tauri/release,src-tauri/gen}"]],
    },
  },
  keys = {
    { "<leader><leader>", "<cmd>FzfLua files<cr>", desc = "Files finder" },
    { "<leader>fs", "<cmd>FzfLua live_grep<cr>", desc = "Live grep" },
    { "<leader>fc", "<cmd>FzfLua lgrep_curbuf<cr>", desc = "Grep current buffer" },
    { "<leader>fb", "<cmd>FzfLua buffers<cr>", desc = "Buffers" },
    { "<leader>ff", "<cmd>FzfLua files<cr>", desc = "Files finder" },
    { "<leader>o", "<cmd>FzfLua lsp_document_symbols<cr>", desc = "Symbols file" },
    { "<leader>fk", "<cmd>FzfLua keymaps<cr>", desc = "Keymaps" },
    { "<leader>a", "<cmd>FzfLua lsp_code_actions<cr>", desc = "Code actions" },
    { "gf", "<cmd>FzfLua lsp_references<cr>", desc = "Show LSP references" },
    { "gD", "<cmd>FzfLua lsp_typedefs<cr>", desc = "Show type definitions" },
    { "gd", "<cmd>FzfLua lsp_definitions<cr>", desc = "Show definitions" },
  },
}
