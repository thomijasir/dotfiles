return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
    "MunifTanjim/nui.nvim",
    -- "3rd/image.nvim", -- Optional image support in preview window: See `# Preview Mode` for more information
  },
  config = function()
    local tree = require("neo-tree")
    tree.setup({
      filesystem = {
        follow_current_file = true, -- Auto-reveal current file
        hijack_netrw_behavior = "open_default", -- Replace netrw with Neo-tree
        use_libuv_file_watcher = true, -- Enable live updates
        filtered_items = {
          hide_dotfiles = true, -- Show hidden files
          hide_gitignored = true, -- Hide git-ignored files
          hide_by_name = { ".DS_Store", "thumbs.db" }, -- Additional ignored files
        },
      },
    })
    -- Keymaps for Neo-tree
    vim.keymap.set("n", "<leader>ee", "<cmd>Neotree toggle<CR>", { desc = "Toggle file explorer" }) -- toggle file explorer
    vim.keymap.set("n", "<leader>ef", "<cmd>Neotree reveal<CR>", { desc = "Reveal current file in file explorer" }) -- reveal current file
    vim.keymap.set("n", "<leader>ec", "<cmd>Neotree close<CR>", { desc = "Close file explorer" }) -- close file explorer
    vim.keymap.set("n", "<leader>er", "<cmd>Neotree refresh<CR>", { desc = "Refresh file explorer" }) -- refresh file explorer
    vim.keymap.set("n", "<leader>eh", "<cmd>Neotree help<CR>", { desc = "Show Neo-tree help" })
  end,
}

