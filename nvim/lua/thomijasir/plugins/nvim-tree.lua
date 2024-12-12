return {
  "nvim-tree/nvim-tree.lua",
  dependencies = "nvim-tree/nvim-web-devicons",
  config = function()
    local nvimtree = require("nvim-tree")
    local api = require("nvim-tree.api")
    -- Custom attach function
    local function on_attach_custom(bufnr)
      local function opts(desc)
        return { desc = desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
      end
      -- Single click handling
      vim.keymap.set('n', '<LeftMouse>', '<LeftMouse>', opts('Click'))
      vim.keymap.set('n', '<LeftRelease>', function()
        -- Only preview if we're clicking in NvimTree buffer
        if vim.bo.filetype == 'NvimTree' then
          api.node.open.preview()
          -- vim.cmd('wincmd p') -- enable this to use always prev mode
        end
      end, opts('Preview'))
      -- Double click handling
      vim.keymap.set('n', '<2-LeftMouse>', function()
        api.node.open.edit()
        -- vim.cmd('stopinsert')  -- Force normal mode
        -- local node = api.tree.get_node_under_cursor()
        -- if node and node.absolute_path then
        --   vim.cmd('edit ' .. vim.fn.fnameescape(node.absolute_path))
        -- end
      end, opts('Open'))
    end
    -- recommended settings from nvim-tree documentation
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1
    -- READ CONFIGURATION: https://github.com/nvim-tree/nvim-tree.lua/blob/master/doc/nvim-tree-lua.txt
    nvimtree.setup({
      on_attach = on_attach_custom,
      -- File focus and directory updates
      update_focused_file = {
        enable = true,
        update_cwd = true,
        ignore_list = {},
      },
      -- View and appearance
      view = {
        width = 40,
        relativenumber = true,
      },
      -- Diagnostics
      diagnostics = {
        enable = true,
        show_on_dirs = true,
      },
      -- Renderer and icons
      renderer = {
        indent_markers = { enable = true },
        root_folder_label = false,
        highlight_git = true, -- Highlight files based on git status
        -- highlight_opened_files = "name", -- Highlight opened files
        -- highlight_modified = "name",
        icons = {
          show = {
            git = false,
          },
        },
      },
      -- Git integration
      git = {
        enable = true,
        ignore = false,
      },
     -- Actions and behavior
      actions = {
        open_file = {
          window_picker = {
            enable = false,
          },
        },
      },
      -- Filters for hidden or unnecessary files
      filters = {
        custom = { ".DS_Store" },
      },
    })
    -- auto open file after create file
    api.events.subscribe(api.events.Event.FileCreated, function(file)
      vim.cmd("edit " .. file.fname)
    end)
    -- Keymaps binding
    vim.keymap.set("n", "<leader>ee", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle file explorer" }) -- toggle file explorer
    vim.keymap.set("n", "<leader>ef", "<cmd>NvimTreeFindFileToggle<CR>", { desc = "Toggle file explorer on current file" }) -- toggle file explorer on current file
    vim.keymap.set("n", "<leader>ec", "<cmd>NvimTreeCollapse<CR>", { desc = "Collapse file explorer" }) -- collapse file explorer
    vim.keymap.set("n", "<leader>er", "<cmd>NvimTreeRefresh<CR>", { desc = "Refresh file explorer" }) -- refresh file explorer
  end,
}
