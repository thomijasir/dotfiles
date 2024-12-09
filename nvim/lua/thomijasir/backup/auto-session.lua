return {
  "rmagatti/auto-session",

  config = function()
    local auto_session = require("thomijasir.backup.auto-session")

    auto_session.setup({
      log_level = "info",
      auto_restore_enabled = false,
      auto_session_enable_last_session = false,
      auto_session_suppress_dirs = { "~/", "~/Dev/", "~/Downloads", "~/Documents", "~/Desktop/" },
      auto_session_root_dir = vim.fn.stdpath("data") .. "/sessions/", -- Directory for session files
      auto_session_use_git_branch = nil, -- Set to true if you want to include Git branch in session names
    })

    -- Auto restore session if one exists for the current directory
    local function restore_session()
      -- Get current directory and encode it
      local current_dir = vim.fn.getcwd()
      local encoded_path = current_dir:gsub("/", "%%2F"):gsub("%%", "%%25")
      local session_file = vim.fn.stdpath("data") .. "/sessions/" .. encoded_path .. ".vim"

      -- Check if session file exists
      if vim.fn.filereadable(session_file) == 1 then
        auto_session.RestoreSession()
      end
    end

    vim.api.nvim_create_autocmd("VimEnter", {
      callback = restore_session,
    })
    -- keymaps
    -- vim.keymap.set("n", "<leader>wl", "<cmd>SessionLoad<CR>", { desc = "Load session" }) -- load last workspace session for current directory
    vim.keymap.set("n", "<leader>wr", "<cmd>SessionRestore<CR>", { desc = "Restore session" }) -- restore last workspace session for current directory
    vim.keymap.set("n", "<leader>ws", "<cmd>SessionSave<CR>", { desc = "Save session" }) -- save workspace session for current working directory
  end,
}
