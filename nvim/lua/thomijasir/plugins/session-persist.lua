return {
  "folke/persistence.nvim",
  event = "BufReadPre",
  opts = {
    -- dir = vim.fn.stdpath("data") .. "/sessions/", -- directory where session files are saved
    -- options = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp" }, -- sessionoptions used for saving
    -- pre_save = nil, -- function to run before saving the session
    -- save_empty = false, -- don't save if there are no open file buffers
  },
  keys = {
    -- restore the session for the current directory
    {
      "<leader>wr",
      function()
        require("persistence").load()
      end,
      desc = "Restore session",
    },
    -- restore the last session
    {
      "<leader>wl",
      function()
        require("persistence").load({ last = true })
      end,
      desc = "Restore last session",
    },
    -- stop Persistence => session won't be saved on exit
    {
      "<leader>wd",
      function()
        require("persistence").stop()
      end,
      desc = "Don't save current session",
    },
    -- save session
    {
      "<leader>ws",
      function()
        require("persistence").save()
      end,
      desc = "Save session",
    },
  },
  config = function(_, opts)
    require("persistence").setup(opts)

    -- Auto-restore session when opening Neovim in a directory with a saved session
    vim.api.nvim_create_autocmd("VimEnter", {
      group = vim.api.nvim_create_augroup("persistence_auto_load", { clear = true }),
      callback = function()
        -- Only load the session if nvim was started with no args
        if vim.fn.argc() == 0 then
          require("persistence").load()
        end
      end,
    })
  end,
}
