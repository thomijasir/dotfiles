return {
  "rmagatti/auto-session",
  opts = {
    log_level = "info",
    root_dir = vim.fn.stdpath("data") .. "/sessions/",
    auto_session_enable_last_session = false,
    auto_session_suppress_dirs = { "~/", "~/Dev/", "~/Downloads", "~/Documents", "~/Desktop/" },
    session_lens = {
      load_on_setup = false,
    },
  },
  config = function(_, opts)
    vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

    local auto_session = require("auto-session")
    auto_session.setup(opts)

    -- keymaps
    vim.keymap.set("n", "<leader>wr", "<cmd>SessionRestore<CR>", { desc = "Restore session" })
    vim.keymap.set("n", "<leader>ws", "<cmd>SessionSave<CR>", { desc = "Save session" })

    -- autorestore
    -- local current_dir = vim.fn.getcwd()
    -- local encoded_path = current_dir:gsub("/", "%%2F"):gsub("%%", "%%25")
    -- local session_file = vim.fn.stdpath("data") .. "/sessions/" .. encoded_path .. ".vim"

    -- print("Session file: " .. session_file)
    -- auto_session.RestoreSession()
  end,
}
