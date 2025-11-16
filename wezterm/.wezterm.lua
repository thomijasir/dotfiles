-- Pull in the wezterm API
local wezterm = require("wezterm")
local act = wezterm.action

-- Simplified tab title with directory
wezterm.on('format-tab-title', function(tab, tabs, panes, config, hover, max_width)
  local cwd = tab.active_pane.current_working_dir
  local dir = cwd and cwd.file_path:match("([^/]+)/?$") or "~"
  return string.format(" %d: %s ", tab.tab_index + 1, dir)
end)

local function switch_pane_and_reload(direction)
  return wezterm.action_callback(function(window, pane)
    -- Switch to the target pane
    window:perform_action(act.ActivatePaneDirection(direction), pane)
    
    -- Small delay to ensure pane is active
    wezterm.sleep_ms(50)
    
    -- Get the newly active pane
    local new_pane = window:active_pane()
    local process = new_pane:get_foreground_process_name()
    
    -- If it's Helix, reload
    if process and process:match('hx$') then
      new_pane:send_text(':reload-all\r')
    end
  end)
end

-- This will hold the configuration.
local config = wezterm.config_builder()

-- Miscellaneous
config.automatically_reload_config = true
config.line_height = 1.05
config.hide_mouse_cursor_when_typing = true
config.underline_position = "-4pt"

-- Tab bar
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = true
config.tab_bar_at_bottom = true
config.tab_and_split_indices_are_zero_based = true
-- Enable enhanced keyboard protocol for better key handling
config.enable_kitty_keyboard = true

-- Window
-- config.initial_cols = 180
-- config.initial_rows = 40
config.window_padding = {
	left = 0,
	bottom = 0,
	top = 0,
	right = 0,
}
-- config.window_background_opacity = 0.9
-- config.macos_window_background_blur = 90
config.window_decorations = "TITLE | RESIZE"
-- config.window_decorations = "RESIZE"
-- Font
-- config.font = wezterm.font("JetBrainsMono Nerd Font Mono")
config.font = wezterm.font("JetBrainsMonoNL Nerd Font")
config.font_size = 16

-- Cursor
config.cursor_blink_ease_in = "Constant"
config.cursor_blink_ease_out = "Constant"
config.default_cursor_style = "BlinkingBlock"

-- Color Scheme
-- config.color_scheme = "Catppuccin Mocha"
-- config.color_scheme = "OneDark (base16)"
-- config.color_scheme = "Google Dark (Gogh)"
-- config.color_scheme = "Homebrew"
-- config.color_scheme = "Greenscreen (dark) (terminal.sexy)"
-- config.color_scheme = "GitHub Dark"
config.color_scheme = "Galaxy"
-- config.color_scheme = "Monokai Pro (Gogh)"
-- TMUX Alternative
config.leader = { key = "a", mods = "ALT", timeout_milliseconds = 2500 }

config.keys = {
	-- Make Alt+Enter work properly
  {
    key = 'Enter',
    mods = 'ALT',
    action = act.SendKey {
      key = 'Enter',
      mods = 'ALT',
    },
  },
  -- LEADER KEY CONTROL
	{
		mods = "LEADER",
		key = "q",
		action = act.PaneSelect,
	},
	{
		mods = "LEADER",
		key = "c",
		action = act.SpawnTab("CurrentPaneDomain"),
	},
	{
		mods = "LEADER",
		key = "x",
		action = act.CloseCurrentPane({ confirm = true }),
	},
	-- PANE CONTROL
	{
		mods = "LEADER",
		key = "LeftArrow",
		action = act.AdjustPaneSize({ "Left", 5 }),
	},
	{
		mods = "LEADER",
		key = "RightArrow",
		action = act.AdjustPaneSize({ "Right", 5 }),
	},
	{
		mods = "LEADER",
		key = "DownArrow",
		action = act.AdjustPaneSize({ "Down", 5 }),
	},
	{
		mods = "LEADER",
		key = "UpArrow",
		action = act.AdjustPaneSize({ "Up", 5 }),
	},
	{
		mods = "LEADER",
		key = "v",
		action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }),
	},
	{
		mods = "LEADER",
		key = "h",
		action = act.SplitVertical({ domain = "CurrentPaneDomain" }),
	},
	{
		mods = "CMD", key = "h",
		action = switch_pane_and_reload("Left"),
	},
	{
		mods = "CMD", key = "j",
		action = switch_pane_and_reload("Down"),
	},
	{
		mods = "CMD", key = "k",
		action = switch_pane_and_reload("Up"),
	},
	{
		mods = "CMD", key = "l",
		action = switch_pane_and_reload("Right"),
	},
	-- Tabs Control
	{
		mods = "CMD", key = "{",
		action = act.ActivateTabRelative(-1)
	},
  {
  	mods = "CMD", key = "}",
  	action = act.ActivateTabRelative(1)
  },
}


-- ==========================================
-- LEADER + NUMBER: Move tab to position
-- ==========================================
for i = 1, 9 do
  table.insert(config.keys, {
    key = tostring(i),
    mods = "LEADER",
    action = act.MoveTab(i - 1),
  })
end

-- ==========================================
-- CMD + NUMBER: Activate specific tab
-- ==========================================
for i = 1, 9 do
  table.insert(config.keys, {
    key = tostring(i),
    mods = "CMD",
    action = act.ActivateTab(i - 1),
  })
end

-- HELIX RELOAD ON OPEN TAB

wezterm.on('reload-helix', function(window, pane)
  local top_process = basename(pane:get_foreground_process_name())
  if top_process == 'hx' then
    local bottom_pane = pane:tab():get_pane_direction('Down')
    if bottom_pane ~= nil then
      local bottom_process = basename(bottom_pane:get_foreground_process_name())
      if bottom_process == 'lazygit' then
        local action = wezterm.action.SendString(':reload-all\r\n')
        window:perform_action(action, pane);
      end
    end
  end
end)

-- ============================================
-- HYPERLINKS CONFIGURATION
-- ============================================

config.hyperlink_rules = wezterm.default_hyperlink_rules()

-- Make localhost URLs clickable
table.insert(config.hyperlink_rules, {
  regex = [[\b(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}):(\d+)\b]],
  format = "http://$1:$2",
})

-- Make file paths clickable
table.insert(config.hyperlink_rules, {
  regex = [[\bfile://([^\s]+)\b]],
  format = "file://$1",
})

-- tmux status | activate this when often use tab menu
-- wezterm.on("update-right-status", function(window, _)
-- 	local SOLID_LEFT_ARROW = ""
-- 	local ARROW_FOREGROUND = { Foreground = { Color = "#c6a0f6" } }
-- 	local prefix = ""
--
-- 	if window:leader_is_active() then
-- 		prefix = " " .. utf8.char(0x1f30a) -- ocean wave
-- 		SOLID_LEFT_ARROW = utf8.char(0xe0b2)
-- 	end
--
-- 	if window:active_tab():tab_id() ~= 0 then
-- 		ARROW_FOREGROUND = { Foreground = { Color = "#1e2030" } }
-- 	end -- arrow color based on if tab is first pane
--
-- 	window:set_left_status(wezterm.format({
-- 		{ Background = { Color = "#b7bdf8" } },
-- 		{ Text = prefix },
-- 		ARROW_FOREGROUND,
-- 		{ Text = SOLID_LEFT_ARROW },
-- 	}))
-- end)
--
return config
