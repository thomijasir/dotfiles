local M = {}

function M.add(specs)
  vim.pack.add(specs, {
    confirm = false,
  })
end

return M
