return {
  "thomijasir/aider-nvim",
  lazy = false,
  config = function()
    local function open_aider_terminal()
      -- Create a new split window at the bottom
      vim.cmd("botright split")
      -- Resize to 15 lines height
      vim.cmd("resize 15")
      -- Open terminal with aider
      vim.cmd("terminal aider")
      -- Enter insert mode automatically
      vim.cmd("startinsert")
    end

    -- Create command to open aider
    vim.api.nvim_create_user_command("Aider", open_aider_terminal, {})
  end,
}
