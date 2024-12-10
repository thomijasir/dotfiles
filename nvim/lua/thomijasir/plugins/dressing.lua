return {
  {
    "stevearc/dressing.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {},
  },
  {
    "NvChad/nvim-colorizer.lua",
    event = "BufReadPre",
    opts = {},
  },
  {
    "folke/noice.nvim",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "NvChad/nvim-colorizer.lua", -- colorizer
    },
    lazy = true,
    event = "VeryLazy",
    opts = {
      views = {
        cmdline_popup = {
          position = {
            row = 10,
            col = "50%",
          },
          size = {
            width = 50,
            height = "auto",
          },
        },
        popupmenu = {
          relative = "editor",
          position = {
            row = 13,
            col = "50%",
          },
          size = {
            width = 60,
            height = 10,
          },
          border = {
            style = "rounded",
            padding = { 0, 1 },
          },
          win_options = {
            winhighlight = { Normal = "Normal", FloatBorder = "DiagnosticInfo" },
          },
        },
      },
      cmdline = {
        enabled = true, -- enables the Noice cmdline UI
        view = "cmdline_popup", -- view for rendering the cmdline. Change to `cmdline` to get a classic cmdline at the bottom
      },
      messages = {
        enabled = true,
        view = "mini", -- default view for messages
        view_error = "mini", -- view for errors
        view_warn = "mini", -- view for warnings
        view_history = "messages", -- view for :messages
        view_search = "virtualtext", -- view for search count messages. Set to `false` to disable
      },
      notify = {
        enabled = false,
        view = "mini",
      },
      routes = {
        {
          filter = {
            event = "msg_show",
            kind = "",
            find = "written",
          },
          opts = { skip = true },
        },
      },
      lsp = {
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"] = true,
        },
      },
      presets = {
        command_palette = true, -- position the cmdline and popupmenu together
        long_message_to_split = true, -- long messages will be sent to a split
        inc_rename = true, -- enables an input dialog for inc-rename.nvim
        lsp_doc_border = true, -- add a border to hover docs and signature help
      },
    },
  },
}
