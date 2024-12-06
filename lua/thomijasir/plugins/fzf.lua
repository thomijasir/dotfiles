local function create_ignore_patterns()
  -- Ignore patterns
  local ignore_paths = {
    ".git",
    "node_modules",
    ".DS_Store",
    "target",
    "release",
    "build",
    "src-tauri/target",
    "src-tauri/release",
    "src-tauri/gen",
    "package-lock.json",
    ".vscode",
    ".idea",
    ".cache",
    "__pycache__",
    "*.py[cod]",
  }

  -- Create fd format (--exclude path1 --exclude path2)
  local fd_pattern = table.concat(
    vim.tbl_map(function(path)
      return "--exclude " .. path
    end, ignore_paths),
    " "
  )

  -- Create rg format (-g "!{path1,path2}")
  local rg_pattern = '-g "!{' .. table.concat(ignore_paths, ",") .. '}"'

  return {
    fd = fd_pattern,
    rg = rg_pattern,
  }
end

local ignore_patterns = create_ignore_patterns()

return {
  "ibhagwan/fzf-lua",
  lazy = true,
  event = "VeryLazy",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    "telescope",
    files = {
      fd_opts = string.format("--color=never --type f --hidden --follow %s", ignore_patterns.fd),
      rg_opts = string.format("--color=never --files --hidden --follow %s", ignore_patterns.rg),
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
