# WezTerm Configuration

Configuration is defined in `.wezterm.lua` and is built with WezTerm's Lua API.

## Look & feel
- Auto-reloads on save and sets a slightly taller `line_height` (1.05) while hiding the mouse cursor when typing.
- Removes window padding and keeps native title/resize decorations.
- Uses the `JetBrainsMonoNL Nerd Font` at size 16 with the `Galaxy` color scheme and a blinking block cursor.
- Keeps the tab bar minimal (`use_fancy_tab_bar = false`) and hides it when only one tab is open, placing it at the bottom if shown.

## Leader workflow
- Defines `ALT+a` as the tmux-style leader with a 2.5s timeout.
- Leader shortcuts cover pane selection (`LEADER+q`), horizontal/vertical splits (`LEADER+|` / `LEADER+-`), pane focus (`LEADER+h/j/k/l`), and pane resizing with arrow keys.
- Tab control includes spawning (`LEADER+c`), cycling (`LEADER+b` / `LEADER+n`), closing (`LEADER+x`), and reordering tabs via `LEADER+1-8`.
- Passes `ALT+Enter` through to applications to fix shells that rely on that combination.

These settings are applied when WezTerm loads `.wezterm.lua`, typically symlinked into the home directory by `setup_env.sh`.
