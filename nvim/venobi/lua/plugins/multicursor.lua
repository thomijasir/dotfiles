local pack = require("utils.pack")

pack.add({
  {
    src = "https://github.com/jake-stewart/multicursor.nvim",
    version = "1.0",
  },
})

local mc = require("multicursor-nvim")

mc.setup()

local map = vim.keymap.set

-- Add a cursor at the next/previous occurrence of the word or selection.
map({ "n", "x" }, "<C-n>", function()
  mc.matchAddCursor(1)
end, { desc = "Multicursor: add next match" })

map({ "n", "x" }, "<C-p>", function()
  mc.matchAddCursor(-1)
end, { desc = "Multicursor: add previous match" })

-- Move past a match without adding a cursor.
map({ "n", "x" }, "<leader>ms", function()
  mc.matchSkipCursor(1)
end, { desc = "Multicursor: skip next match" })

map({ "n", "x" }, "<leader>mS", function()
  mc.matchSkipCursor(-1)
end, { desc = "Multicursor: skip previous match" })

map({ "n", "x" }, "<leader>ma", mc.matchAllAddCursors, {
  desc = "Multicursor: add all matches",
})

map({ "n", "x" }, "<leader>mt", mc.toggleCursor, {
  desc = "Multicursor: toggle cursor",
})

mc.addKeymapLayer(function(layer_map)
  layer_map({ "n", "x" }, "<Left>", mc.prevCursor)
  layer_map({ "n", "x" }, "<Right>", mc.nextCursor)
  layer_map({ "n", "x" }, "<leader>mx", mc.deleteCursor)

  layer_map("n", "<Esc>", function()
    if not mc.cursorsEnabled() then
      mc.enableCursors()
    else
      mc.clearCursors()
    end
  end)
end)
