# Yazi Configuration

This directory holds the settings for the Yazi TUI file manager.

## Core options (`yazi.toml`)
- Enables hidden files and symlinks by default, with a three-panel ratio of `0:2:4`.
- Displays entries in `size` line mode and sorts directories first using alphabetical ordering.
- Registers a simple editor opener that launches `hx` (Helix) whenever `edit` is triggered.
- Prepends the bundled git metadata fetcher for all entries, so git status badges render inside the file list.

## Key bindings (`keymap.toml`)
- `c m` runs the `chmod` plugin on the current selection for quick permission tweaks.
- `l` invokes `smart-enter`, opening directories or launching viewers intelligently.
- `F` calls `smart-filter` to filter items with contextual defaults.

## Plugins (`package.toml` & `init.lua`)
- Declares dependencies on official Yazi plugins: `smart-enter`, `git`, `smart-filter`, and `chmod`.
- Pins each plugin to a specific revision and integrity hash for reproducible installs.
- `init.lua` wires up the git plugin so repository status indicators are active at startup.

These files are consumed automatically when Yazi is pointed at this configuration directory (e.g. via the symlink created in `setup_env.sh`).
