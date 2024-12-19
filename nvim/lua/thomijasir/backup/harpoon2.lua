return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  config = true,
  keys = {
    {
      "<leader>hm",
      function()
        require("harpoon"):list():add()
        print("File marked! ")
      end,
      desc = "Harpoon markfile",
    },
    {
      "<leader>hn",
      function()
        require("harpoon"):list():next()
      end,
      desc = "Harpoon next mark",
    },
    {
      "<leader>hz",
      function()
        require("harpoon"):list():prev()
      end,
      desc = "Harpoon previous mark",
    },
    {
      "<leader>hx",
      function()
        require("harpoon"):list():remove()
        print("File unmarked! ")
      end,
      desc = "Harpoon remove",
    },
    {
      "<leader>ha",
      function()
        local harpoon = require("harpoon")
        harpoon.ui:toggle_quick_menu(harpoon:list())
      end,
      desc = "Harpoon menu",
    },
  },
}
