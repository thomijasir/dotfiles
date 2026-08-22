local pack = require("utils.pack")

pack.add({ { src = "https://github.com/lewis6991/gitsigns.nvim", version = "stable" } })

require("gitsigns").setup({
  -- Attach to untracked files so on_attach keymaps (which-key, staging) work in new files
  attach_to_untracked = true,
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
        gitsigns.nav_hunk("next", { target = "all" })
      end
    end, { desc = "Next Git hunk" })

    map("n", "[c", function()
      if vim.wo.diff then
        vim.cmd.normal({ "[c", bang = true })
      else
        gitsigns.nav_hunk("prev", { target = "all" })
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

    map("n", "<leader>hS", gitsigns.stage_buffer, { desc = "Stage entire buffer" })

    map("n", "<leader>hU", gitsigns.reset_buffer_index, { desc = "Unstage entire buffer" })

    map("n", "<leader>hr", gitsigns.reset_hunk, {
      desc = "Reset Git hunk",
    })

    map("x", "<leader>hr", function()
      gitsigns.reset_hunk({
        vim.fn.line("."),
        vim.fn.line("v"),
      })
    end, { desc = "Reset selected Git hunk" })

    map("n", "<leader>hR", gitsigns.reset_buffer, { desc = "Reset entire buffer" })

    map("n", "<leader>hp", gitsigns.preview_hunk, {
      desc = "Preview Git hunk",
    })

    -- Diffing
    map("n", "<leader>hd", gitsigns.diffthis, { desc = "Diff against index" })
    map("n", "<leader>hD", function()
      gitsigns.diffthis("~")
    end, { desc = "Diff against last commit" })

    -- Hunk Overview
    map("n", "<leader>hq", gitsigns.setqflist, { desc = "All hunks in file to quickfix" })
    map("n", "<leader>hQ", function()
      gitsigns.setqflist("all")
    end, { desc = "All changed files to quickfix" })

    -- UI Toggles
    map("n", "<leader>gt", gitsigns.toggle_current_line_blame, { desc = "Toggle inline blame" })
    map("n", "<leader>gw", gitsigns.toggle_word_diff, { desc = "Toggle word diff" })

    map("n", ";b", function()
      gitsigns.blame_line({ full = true })
    end, { desc = "Git Blame line" })

    map("n", ";B", function()
      gitsigns.blame()
    end, { desc = "Git Blame list" })

    map({ "o", "x" }, "ih", gitsigns.select_hunk, {
      desc = "Inside Git hunk",
    })
  end,
})
