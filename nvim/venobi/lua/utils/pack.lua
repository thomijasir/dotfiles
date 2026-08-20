local M = {}

function M.add(specs, opts)
  opts = opts or {}

  vim.pack.add(specs, {
    confirm = false,
    load = not opts.lazy,
  })
end

return M
