local pack = require("utils.pack")

pack.add({
  {
    src = "https://github.com/ibhagwan/fzf-lua",
  },
})

local fzf = require("fzf-lua")

fzf.setup({
  defaults = {
    file_icons = true,
    git_icons = true,
    color_icons = true,
  },

  winopts = {
    height = 0.85,
    width = 0.85,
    row = 0.5,
    col = 0.5,
    border = "rounded",

    preview = {
      border = "rounded",
      layout = "flex",
      scrollbar = "float",
    },
  },

  files = {
    cwd_prompt = false,
    hidden = true,
  },

  grep = {
    rg_glob = true,
    hidden = true,
  },

  keymap = {
    builtin = {
      ["<C-f>"] = "preview-page-down",
      ["<C-b>"] = "preview-page-up",
    },

    fzf = {
      ["ctrl-q"] = "select-all+accept",
    },
  },
})

fzf.register_ui_select()

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    local arg = vim.fn.argv(0)
    -- Check if Neovim was launched with a directory argument
    if arg ~= "" and vim.fn.isdirectory(arg) == 1 then
      require("fzf-lua").files()
    end
  end,
})

local map = vim.keymap.set

map("n", "<leader>,", fzf.buffers, {
  desc = "Find buffers",
})

map("n", "<leader>/", function()
  fzf.live_grep({
    rg_glob = true,
  })
end, {
  desc = "Find string",
})

map("n", "<leader>d", fzf.diagnostics_document, {
  desc = "Document diagnostics",
})

map("n", "<leader>D", fzf.diagnostics_workspace, {
  desc = "Workspace diagnostics",
})

map("n", "<leader>ss", fzf.lsp_document_symbols, {
  desc = "Document symbols",
})

map("n", "<leader>sS", fzf.lsp_workspace_symbols, {
  desc = "Workspace symbols",
})

map("n", "<leader>f", fzf.files, {
  desc = "Find files",
})

map("n", "<leader>Fw", fzf.grep_cword, {
  desc = "Search word under cursor",
})

map("v", "<leader>Fw", fzf.grep_visual, {
  desc = "Search selected text",
})

map("n", "<leader>Fr", fzf.oldfiles, {
  desc = "Recent files",
})

map("n", "<leader>Fh", fzf.helptags, {
  desc = "Search help",
})

map("n", "<leader>Fc", fzf.commands, {
  desc = "Search commands",
})

map("n", "<leader>Fk", fzf.keymaps, {
  desc = "Search keymaps",
})

map("n", "<leader>gf", fzf.git_files, {
  desc = "Find Git files",
})

map("n", "<leader>gs", fzf.git_status, {
  desc = "Git status",
})

map("n", "<leader>gc", fzf.git_commits, {
  desc = "Git commits",
})

map("n", "<leader>gb", fzf.git_branches, {
  desc = "Git branches",
})
