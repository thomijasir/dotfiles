local pack = require("utils.pack")

pack.add({
  {
    src = "https://github.com/lewis6991/satellite.nvim",
  },
})

local excluded_filetypes = {
  "bigfile",
  "help",
  "minifiles",
  "qf",
  "trouble",
}

local function set_conflict_highlight()
  vim.api.nvim_set_hl(0, "SatelliteConflict", {
    default = true,
    link = "DiagnosticWarn",
  })
end

set_conflict_highlight()

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("UserSatelliteConflict", { clear = true }),
  callback = set_conflict_highlight,
  desc = "Restore the conflict marker color",
})

local conflict_handler = {
  name = "conflict",
  config = {
    enable = true,
    overlap = true,
    priority = 90,
  },
}

local conflict_cache = {}

function conflict_handler.setup(config)
  conflict_handler.config = vim.tbl_deep_extend("force", conflict_handler.config, config)

  vim.api.nvim_create_autocmd("BufWipeout", {
    group = vim.api.nvim_create_augroup("UserSatelliteConflictCache", { clear = true }),
    callback = function(event)
      conflict_cache[event.buf] = nil
    end,
    desc = "Clear cached conflict markers",
  })
end

function conflict_handler.update(buffer, window)
  local async = require("satellite.async")
  local util = require("satellite.util")
  local changedtick = vim.b[buffer].changedtick
  local cached = conflict_cache[buffer]

  if not cached or cached.changedtick ~= changedtick then
    local predicate = util.winbuf_pred(buffer, window)
    local conflict_lines = {}
    local line_count = vim.api.nvim_buf_line_count(buffer)
    local chunk_size = 1000
    local start_time = vim.uv.hrtime()

    for first_line = 0, line_count - 1, chunk_size do
      if predicate() == false then
        return {}
      end

      local last_line = math.min(first_line + chunk_size, line_count)
      local lines = vim.api.nvim_buf_get_lines(buffer, first_line, last_line, false)

      for offset, line in ipairs(lines) do
        if line:find("^<<<<<<<") then
          table.insert(conflict_lines, first_line + offset - 1)
        end
      end

      start_time = async.event_control(start_time)

      if predicate() == false then
        return {}
      end
    end

    cached = {
      changedtick = changedtick,
      lines = conflict_lines,
    }
    conflict_cache[buffer] = cached
  end

  local marks = {}
  for _, line_number in ipairs(cached.lines) do
    table.insert(marks, {
      pos = util.row_to_barpos(window, line_number),
      highlight = "SatelliteConflict",
      symbol = "!",
    })
  end

  return marks
end

require("satellite.handlers").register(conflict_handler)

require("satellite").setup({
  current_only = true,
  winblend = 0,
  excluded_filetypes = excluded_filetypes,
  handlers = {
    cursor = { enable = false },
    search = { enable = false },
    diagnostic = {
      enable = true,
      overlap = true,
      priority = 80,
      min_severity = vim.diagnostic.severity.WARN,
      signs = {
        error = { "━", "━", "━" },
        warn = { "━", "━", "━" },
      },
    },
    gitsigns = {
      enable = true,
      overlap = true,
      priority = 30,
      signs = {
        add = "│",
        change = "│",
        delete = "_",
      },
    },
    conflict = conflict_handler.config,
    marks = { enable = false },
    quickfix = { enable = false },
  },
})

-- threshold minimum line to open satellite
local satellite_line_threshold = 100
local excluded_filetype = {}
for _, filetype in ipairs(excluded_filetypes) do
  excluded_filetype[filetype] = true
end

local function should_show_satellite()
  local buffer = vim.api.nvim_get_current_buf()
  local window = vim.api.nvim_get_current_win()
  local util = require("satellite.util")

  return util.is_ordinary_window(window)
    and vim.bo[buffer].buftype == ""
    and vim.api.nvim_buf_get_name(buffer) ~= ""
    and not excluded_filetype[vim.bo[buffer].filetype]
    and not vim.wo[window].winfixbuf
    and vim.api.nvim_buf_line_count(buffer) >= satellite_line_threshold
end

local function update_satellite_visibility()
  local view = require("satellite.view")
  local should_show = should_show_satellite()

  if should_show and not view.enabled() then
    view.enable()
  elseif not should_show and view.enabled() then
    view.disable()
  end
end

vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "WinEnter", "TextChanged", "BufWritePost" }, {
  group = vim.api.nvim_create_augroup("UserSatelliteVisibility", { clear = true }),
  callback = function()
    vim.schedule(update_satellite_visibility)
  end,
  desc = "Show the overview ruler for long files",
})

update_satellite_visibility()
