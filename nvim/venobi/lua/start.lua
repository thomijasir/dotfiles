-- External CLI tools the config depends on. Checked at startup so missing
-- dependencies surface early instead of failing silently when a feature is used.
local required_tools = {
  { name = "git", desc = "version control (gitsigns, fzf-lua git commands)" },
  { name = "fzf", desc = "fuzzy-finder engine (fzf-lua)" },
  { name = "rg", desc = "ripgrep (fzf-lua live_grep)" },
  { name = "fd", desc = "file search (fzf-lua)" },
  { name = "node", desc = "Node.js (LSPs: vtsls, vue_ls, tailwindcss, eslint, prettierd)" },
  { name = "lazygit", desc = "Git TUI (snacks.lazygit)" },
  { name = "ast-grep", desc = "A CLI tool for code structural search" },
}

local missing = {}
for _, tool in ipairs(required_tools) do
  if vim.fn.executable(tool.name) == 0 then
    table.insert(missing, tool)
  end
end

if #missing > 0 then
  local lines = { "nvim: missing external tools — refusing to start:" }
  for _, tool in ipairs(missing) do
    table.insert(lines, ("  • %-9s %s"):format(tool.name, tool.desc))
  end
  table.insert(lines, "")
  table.insert(lines, "Install them or add to your PATH, then restart nvim.")
  -- Show the message in a confirm dialog so it stays visible, then exit on
  -- confirmation instead of closing instantly (default action: Exit).
  local choice = vim.fn.confirm(table.concat(lines, "\n"), "&Exit\n&Continue", 1, "Error")
  if choice == 1 then
    vim.cmd("cquit 1")
  end
end
