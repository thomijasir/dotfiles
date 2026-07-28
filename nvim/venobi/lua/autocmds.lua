local nvim_set = vim.api.nvim_set_hl
local autocmd = vim.api.nvim_create_autocmd

autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
  callback = function(event)
    -- Helper function for buffer-local mappings
    local map = function(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = event.buf, desc = "LSP: " .. desc })
    end

    map("n", "gd", vim.lsp.buf.definition, "Go to Definition")
    map("n", "gD", vim.lsp.buf.declaration, "Go to Declaration")
    map("n", "K", vim.lsp.buf.hover, "Hover")
    map("n", "<leader>rn", vim.lsp.buf.rename, "Rename Symbol")
    map({ "n", "v" }, "<leader>a", vim.lsp.buf.code_action, "Code Action")
  end,
})

autocmd("TextYankPost", {
  callback = function()
    vim.hl.on_yank({
      higroup = "YankHighlight",
      timeout = 300,
    })
  end,
  desc = "Highlight yanked or deleted text",
})

autocmd("ColorScheme", {
  callback = function()
    nvim_set(0, "DiagnosticUnderlineError", {
      undercurl = true,
      sp = "#ff5555",
    })
    nvim_set(0, "DiagnosticUnderlineWarn", {
      undercurl = true,
      sp = "#ffaa00",
    })
    nvim_set(0, "DiagnosticUnderlineInfo", {
      undercurl = true,
      sp = "#00afff",
    })
    nvim_set(0, "DiagnosticUnderlineHint", {
      undercurl = true,
      sp = "#00ff88",
    })
    -- YankHighlight
    nvim_set(0, "YankHighlight", {
      fg = "#24273a",
      bg = "#eed49f",
      bold = true,
    })
  end,
})
