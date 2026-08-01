# Repository Guidelines

## Project Structure & Module Organization

Top-level directories such as `helix/`, `nvim/`, `yazi/`, `wezterm/`, `ghostty/`, and `lazygit/` contain application configs. `nvim/venobi/` is the active Neovim configuration and must be used for all new Neovim work; other profiles under `nvim/` are legacy and should not receive features or routine maintenance. Command-line helpers live in `scripts/`, Docker Compose examples in `compose/`, and shared SVG assets in `icons/`. Platform installers are split between `mac/` and `linux/`; `setup.sh` dispatches to the correct one. Keep new files near the tool they configure.

## Build, Test, and Development Commands

There is no compiled build or unified test suite. Use focused validation before running installers:

- `bash -n setup.sh mac/setup.sh scripts/*.sh` checks shell syntax without changing the machine.
- `python3 -m py_compile linux/setup.py scripts/*.py` validates Python syntax.
- `stylua --check nvim/venobi/lua` checks Lua formatting for the Venobi Neovim profile.
- `docker compose -f compose/<service>.yml config` validates a Compose file.
- `./setup.sh` starts the interactive platform setup; review its package scripts first because it installs software and creates symlinks.

## Coding Style & Naming Conventions

Follow the surrounding file's style. Shell scripts should use Bash, quote expansions, prefer `set -euo pipefail` for new standalone scripts, and use descriptive `snake_case` functions. Python uses four spaces and `snake_case`; Lua formatting follows `nvim/venobi/stylua.toml` (two spaces, 120-column width). Use lowercase tool directory names. Linux package scripts retain the ordered pattern `NN-description.sh`; Compose files use descriptive lowercase names.

## Testing Guidelines

Treat syntax checks as the minimum requirement and test only the affected platform or tool. For Neovim changes, symlink or install `nvim/venobi/` as the active config, launch Neovim, and confirm startup completes without errors; do not validate or extend legacy profiles. For other config changes, launch the relevant application and confirm it loads correctly. Do not run full installers for a small edit. When changing symlink scripts, verify the source and destination and avoid overwriting user configuration.

## Commit & Pull Request Guidelines

Recent commits use short, imperative, scope-prefixed subjects, for example `nvim: update keymaps` or `fix: tabs error`. Keep each commit focused on one tool or concern. Pull requests should summarize the behavior changed, list platforms tested, identify installation or symlink side effects, and include screenshots only for visible terminal/editor changes. Link related issues when applicable and never commit credentials, machine-specific secrets, or private paths.
