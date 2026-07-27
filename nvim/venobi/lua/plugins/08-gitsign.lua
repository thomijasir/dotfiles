local pack = require("utils.pack")

pack.add({ { src = "https://github.com/lewis6991/gitsigns.nvim" } })

require("gitsigns").setup({
  on_attach = function(buffer)
    local gitsigns = require("gitsigns")

    local function map(mode, lhs, rhs, opts)
      opts = opts or {}
      opts.buffer = buffer
      vim.keymap.set(mode, lhs, rhs, opts)
    end

    map("n", "]c", function()
      if vim.wo.diff then
        vim.cmd.normal({ "]c", bang = true })
      else
        gitsigns.nav_hunk("next")
      end
    end, { desc = "Next Git hunk" })

    map("n", "[c", function()
      if vim.wo.diff then
        vim.cmd.normal({ "[c", bang = true })
      else
        gitsigns.nav_hunk("prev")
      end
    end, { desc = "Previous Git hunk" })

    map("n", "<leader>hs", gitsigns.stage_hunk, {
      desc = "Stage Git hunk",
    })

    map("x", "<leader>hs", function()
      gitsigns.stage_hunk({
        vim.fn.line("."),
        vim.fn.line("v"),
      })
    end, { desc = "Stage selected Git hunk" })

    map("n", "<leader>hr", gitsigns.reset_hunk, {
      desc = "Reset Git hunk",
    })

    map("x", "<leader>hr", function()
      gitsigns.reset_hunk({
        vim.fn.line("."),
        vim.fn.line("v"),
      })
    end, { desc = "Reset selected Git hunk" })

    map("n", "<leader>hp", gitsigns.preview_hunk, {
      desc = "Preview Git hunk",
    })

    map("n", "<leader>hb", function()
      gitsigns.blame_line({ full = true })
    end, { desc = "Blame current line" })

    map({ "o", "x" }, "ih", gitsigns.select_hunk, {
      desc = "Inside Git hunk",
    })
  end,
})
