-- Automatic detect package inside plugins folder
local plugins_dir = vim.fn.stdpath("config") .. "/lua/plugins"

local plugin_files = vim.fn.globpath(plugins_dir, "*.lua", false, true)

table.sort(plugin_files)

for _, filepath in ipairs(plugin_files) do
  local filename = vim.fn.fnamemodify(filepath, ":t:r")
  -- Load each plugin in isolation so a single broken file doesn't abort the
  -- rest of the config. Files with a non-.lua extension (e.g. *.disable) are
  -- skipped automatically by the glob pattern above.
  local ok, err = pcall(require, "plugins." .. filename)
  if not ok then
    vim.notify(("Failed to load plugins.%s:\n%s"):format(filename, err), vim.log.levels.ERROR)
  end
end
