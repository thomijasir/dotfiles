return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = {
    bigfile = { enabled = false },
    bufdelete = { enabled = false },
    dashboard = {
      enabled = true,
      sections = {
        { section = "header" },
        { section = "keys", gap = 1 },
        { icon = " ", title = "Projects", section = "projects", padding = { 2, 1 } },
        -- { icon = " ", title = "Recent Files", section = "recent_files", indent = 1, padding = 1 },
        { section = "startup" },
      },
    },
    git = { enabled = false },
    notifier = { enabled = false },
    notify = { enabled = false },
    quickfile = { enabled = true },
    rename = { enabled = false },
    statuscolumn = { enabled = false },
    terminal = {
      enabled = true,
      win = {
        position = "float",
        border = "single",
      },
    },
    toggle = { enabled = false },
    words = { enabled = false },
    styles = {
      notification = {
        wo = { wrap = true }, -- Wrap notifications
      },
    },
  },
  keys = {
    {
      "<leader>tt",
      function()
        require("snacks").terminal.toggle()
      end,
      desc = "Terminal",
    },
    {
      "<leader>tv",
      function()
        require("snacks").terminal.toggle("lazydocker")
      end,
      desc = "LazyDocker",
    },
    {
      "<leader>gb",
      function()
        require("snacks").git.blame_line()
      end,
      desc = "Git Blame Line",
    },
    {
      "<leader>gB",
      function()
        require("snacks").gitbrowse()
      end,
      desc = "Git Browse",
    },
    {
      "<leader>gf",
      function()
        require("snacks").lazygit.log_file()
      end,
      desc = "Lazygit Current File History",
    },
    {
      "<leader>gl",
      function()
        require("snacks").lazygit.log()
      end,
      desc = "Lazygit Log (cwd)",
    },
  },
}
