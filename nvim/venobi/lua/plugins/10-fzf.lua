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
    if vim.fn.argc() ~= 1 then
      return
    end

    local directory = vim.fn.fnamemodify(vim.fn.argv(0), ":p")
    if vim.fn.isdirectory(directory) ~= 1 then
      return
    end

    vim.cmd.cd(vim.fn.fnameescape(directory))
    vim.cmd.enew()
    vim.schedule(function()
      fzf.files({ cwd = directory })
    end)
  end,
})

local map = vim.keymap.set

map("n", "<leader>/", fzf.live_grep, {
  desc = "Find string",
})

map("n", "<leader>ff", fzf.files, {
  desc = "Find files",
})

map("n", "<leader>fg", fzf.live_grep, {
  desc = "Search project text",
})

map("n", "<leader>fw", fzf.grep_cword, {
  desc = "Search word under cursor",
})

map("v", "<leader>fw", fzf.grep_visual, {
  desc = "Search selected text",
})

map("n", "<leader>fb", fzf.buffers, {
  desc = "Find buffers",
})

map("n", "<leader>fr", fzf.oldfiles, {
  desc = "Recent files",
})

map("n", "<leader>fh", fzf.helptags, {
  desc = "Search help",
})

map("n", "<leader>fc", fzf.commands, {
  desc = "Search commands",
})

map("n", "<leader>fk", fzf.keymaps, {
  desc = "Search keymaps",
})

map("n", "<leader>fd", fzf.diagnostics_document, {
  desc = "Document diagnostics",
})

map("n", "<leader>fD", fzf.diagnostics_workspace, {
  desc = "Workspace diagnostics",
})

map("n", "<leader>fs", fzf.lsp_document_symbols, {
  desc = "Document symbols",
})

map("n", "<leader>fS", fzf.lsp_workspace_symbols, {
  desc = "Workspace symbols",
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
