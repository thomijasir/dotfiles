-- Automatic detect package inside plugins folder
local plugins_dir = vim.fn.stdpath("config") .. "/lua/plugins"

local plugin_files = vim.fn.globpath(
  plugins_dir,
  "*.lua",
  false,
  true
)

table.sort(plugin_files)

for _, filepath in ipairs(plugin_files) do
  local filename = vim.fn.fnamemodify(filepath, ":t:r")
  require("plugins." .. filename)
end
