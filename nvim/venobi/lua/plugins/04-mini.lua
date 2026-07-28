local pack = require("utils.pack")
pack.add({
  {
    src = "https://github.com/nvim-mini/mini.nvim",
    version = "stable",
  },
  -- Support dependency mini files to show image
  {
    src = "https://github.com/3rd/image.nvim",
  },
  {
    src = "https://github.com/hmdfrds/focal.nvim",
  },
})

require("mini.pairs").setup()
require("mini.surround").setup()

local icons = require("mini.icons")
icons.setup()
icons.mock_nvim_web_devicons()

local statusline = require("mini.statusline")

statusline.setup({
  content = {
    active = function()
      local mode, mode_hl = statusline.section_mode({ trunc_width = math.huge })
      local diagnostics = statusline.section_diagnostics({ trunc_width = 70 })

      return statusline.combine_groups({
        { hl = mode_hl, strings = { mode } },
        "%<",
        { hl = "MiniStatuslineFilename", strings = { "%t%m%r" } },
        "%=",
        { hl = "MiniStatuslineDevinfo", strings = { diagnostics, "%S" } },
        { hl = mode_hl, strings = { "%l:%v2~%L" } },
      })
    end,
    inactive = function()
      return "%#MiniStatuslineInactive# %t%="
    end,
  },
})

require("mini.files").setup({
  mappings = {
    go_in = "L",
    go_in_plus = "l",
  },

  options = {
    use_as_default_explorer = false,
  },

  windows = {
    preview = true,
    width_focus = 30,
    width_nofocus = 15,
    width_preview = 50,
  },
})

---@diagnostic disable-next-line: missing-fields
require("image").setup({
  backend = "kitty", -- Ghostty uses the Kitty graphics protocol
  max_height_window_percentage = 40,
  max_width_window_percentage = 40,
  window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
})

require("focal").setup({
  enabled = true,
  border = "rounded",
})

local jump2d = require("mini.jump2d")

jump2d.setup({
  labels = "asdfghjklqwertyuiopzxcvbnm",
  view = {
    dim = true,
    n_steps_ahead = 2,
  },
  mappings = {
    start_jumping = "",
  },
  silent = true,
})

local map = vim.keymap.set

map({ "n", "x", "o" }, "gw", function()
  jump2d.start(jump2d.builtin_opts.word_start)
end, {
  desc = "Jump to visible word",
})

map("n", "<C-e>", function()
  local current_file = vim.api.nvim_buf_get_name(0)
  local anchor = vim.fn.filereadable(current_file) == 1 and current_file or vim.fn.getcwd()
  MiniFiles.open(anchor)
end, {
  desc = "Open file explorer at current file",
})
