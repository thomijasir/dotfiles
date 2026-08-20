local pack = require("utils.pack")

pack.add({
  {
    src = "https://github.com/folke/snacks.nvim",
    version = "stable",
  },
  -- Support dependency mini files to show image
  {
    src = "https://github.com/3rd/image.nvim",
  },
  {
    src = "https://github.com/hmdfrds/focal.nvim",
    version = "stable",
  },
})

local custom_config_path = vim.fn.stdpath("config") .. "/lazygit.yml"
local map = vim.keymap.set

---@diagnostic disable-next-line: missing-fields
require("image").setup({
  backend = "kitty", -- Ghostty uses the Kitty graphics protocol
  -- Snacks owns direct image buffers and fzf-lua previews. Keep image.nvim
  -- focused on document and Focal previews so both plugins do not render the
  -- same image buffer.
  hijack_file_patterns = {},
  integrations = {
    markdown = {
      enabled = true,
      only_render_image_at_cursor = true,
      only_render_image_at_cursor_mode = "popup",
    },
    asciidoc = { enabled = false },
    typst = { enabled = false },
    neorg = { enabled = false },
    syslang = { enabled = false },
  },
  max_height_window_percentage = 40,
  max_width_window_percentage = 40,
  window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
})

require("focal").setup({
  enabled = true,
  backend = "image.nvim",
  border = "rounded",
})

require("snacks").setup({
  -- Avoid attaching expensive editor features to minified or otherwise
  -- oversized files.
  bigfile = { enabled = true },
  -- Render an explicitly opened file before the rest of startup completes.
  quickfile = { enabled = true },
  -- Highlight and navigate references reported by the attached LSP.
  words = { enabled = true },
  -- Enables high-res image previews for Ghostty (also powers fzf-lua image previews).
  -- `doc` is disabled so it does not double-render inline markdown images that
  -- image.nvim already handles; fzf-lua previews are unaffected (they use the
  -- image module directly, not `doc`).
  image = {
    enabled = true,
    doc = { enabled = false },
    -- `svg` is not in snacks.image's default `formats`, so add it so the
    -- builtin fzf-lua previewer renders SVG as an image (via ImageMagick's
    -- `vector` converter / rsvg-convert delegate) instead of raw XML text.
    formats = {
      "png",
      "jpg",
      "jpeg",
      "gif",
      "bmp",
      "webp",
      "tiff",
      "heic",
      "avif",
      "mp4",
      "mov",
      "avi",
      "mkv",
      "webm",
      "pdf",
      "icns",
      "svg",
    },
  },
  bufdelete = { enabled = true },
  indent = { enabled = true },
  lazygit = {
    enabled = true,
  },
})

-- Notify attached LSP clients when MiniFiles moves or renames a file so they
-- can update imports and other workspace references.
vim.api.nvim_create_autocmd("User", {
  pattern = "MiniFilesActionRename",
  callback = function(event)
    Snacks.rename.on_rename_file(event.data.from, event.data.to)
  end,
  desc = "Notify LSP clients after MiniFiles rename",
})

-- Resolve LazyGit's config directory lazily (only when `;g` is pressed) and
-- cache the result, so startup never shells out to `lazygit`.
local lazygit_args ---@type string[]?

local function get_lazygit_args()
  if lazygit_args then
    return lazygit_args
  end

  local config_dir = vim.fn.systemlist({ "lazygit", "--print-config-dir" })[1] or ""

  if vim.v.shell_error ~= 0 or config_dir == "" then
    return nil
  end

  lazygit_args = {
    "--use-config-file",
    config_dir .. "/config.yml," .. custom_config_path,
  }
  return lazygit_args
end

map("n", ";g", function()
  if vim.fn.executable("lazygit") == 0 then
    vim.notify("lazygit is not installed", vim.log.levels.WARN)
    return
  end

  Snacks.lazygit({
    win = {
      width = 0,
      height = 0,
    },
    args = get_lazygit_args(),
  })
end, {
  desc = "Open LazyGit",
  silent = true,
})

map("n", "<leader>bd", function()
  Snacks.bufdelete()
end, { desc = "Close buffer" })

map("n", "<leader>bo", function()
  Snacks.bufdelete.other()
end, { desc = "Close other buffer" })

map("n", "]r", function()
  Snacks.words.jump(vim.v.count1)
end, { desc = "Next LSP reference" })

map("n", "[r", function()
  Snacks.words.jump(-vim.v.count1)
end, { desc = "Previous LSP reference" })

map("n", "<leader>.", function()
  Snacks.scratch()
end, { desc = "Toggle scratch buffer" })

map("n", "<leader>S", function()
  Snacks.scratch.select()
end, { desc = "Select scratch buffer" })

map({ "n", "t" }, "<C-/>", function()
  Snacks.terminal()
end, { desc = "Toggle terminal" })

map("n", "<leader>cr", function()
  Snacks.rename.rename_file()
end, { desc = "Rename file" })
