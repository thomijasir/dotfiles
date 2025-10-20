# Dotfiles

Opinionated macOS development environment powered by zsh, WezTerm, Neovim, Helix, and Yazi. The repository lives in `~/Workspace/dotfiles` and exposes scripts that wire everything together with sensible defaults for daily work.

## What's inside
- `zshrc/.zshrc` & `zshrc/.zshrc.sample`: shell configuration with Android/Java toolchains, bun, pyenv, NVM, and an extensive alias collection tailored for git, dev tooling, and frequently used scripts.
- `wezterm/.wezterm.lua`: terminal profile, fonts, and keymaps for WezTerm.
- `lazyvim/`: LazyVim-based Neovim distribution (default symlink target) with plugins tracked via `lazy-lock.json` and overrides in `lua/`.
- `nvim/`: alternative, lightweight Neovim configuration if you prefer a non-LazyVim setup.
- `helix/`: Helix editor configuration with a custom Sonokai theme, ergonomic keymaps, and workflow tweaks.
- `yazi/`: file manager presets, git integration plugin, and launcher helpers.
- `icons/`: SVG icon set that can be reused across terminals, prompts, or personal sites.
- `setup_env.sh`, `setup_nvim.sh`, `nvim_setup.md`: bootstrap scripts and notes for installing prerequisites.

## Bootstrapping
1. Clone into `~/Workspace` (the scripts assume this exact path):
   ```bash
   git clone git@github.com:<you>/dotfiles.git ~/Workspace/dotfiles
   cd ~/Workspace/dotfiles
   ```
2. Inspect and run `./setup_env.sh` (macOS only). It will:
   - reveal hidden files in Finder;
   - create `~/.config` if needed and symlink zsh, WezTerm, Yazi, and the LazyVim Neovim profile;
   - install Homebrew, Rust (plus `cargo-watch`), bun, NVM, WezTerm, Nerd Fonts, and zsh autosuggestion/highlighting plugins.
3. Run `./setup_nvim.sh` to pull in the CLI tools that Neovim depends on: `ripgrep`, `fd`, `fzf`, `lazygit`, `lazydocker`, `jq`, `zoxide`, `imagemagick`, `yazi`, etc.
4. Restart the terminal (or run `source ~/.zshrc`) so the new PATH entries, completions, and aliases take effect.

> **Note**: Both setup scripts use `curl` and `brew` installers. Review before running if you prefer to execute each command manually.

## Switching Neovim profiles
`setup_env.sh` links `~/.config/nvim` to the LazyVim configuration by default. To swap to the minimal profile or back again:
```bash
rm ~/.config/nvim
ln -s ~/Workspace/dotfiles/nvim ~/.config/nvim   # Minimal
# or
ln -s ~/Workspace/dotfiles/lazyvim ~/.config/nvim # LazyVim
```

Additional plugin, LSP, and formatter suggestions live in `nvim_setup.md` for reference.

## Shell highlights
- Paths preloaded for Android SDK/NDK, Java 17, Flutter, bun, pyenv, NVM, RVM, and VS Code command line tools.
- Productivity aliases for git, cleanup tasks, editor shortcuts (`nvim_config`, `wezterm_config`, `zsh_config`), and custom scripts.
- History sharing, autosuggestions, and syntax highlighting via Homebrew installs.
- Prompt configured with `vcs_info` to display the current git branch.

## Editor & TUI tooling
- **Helix**: relative numbering, clipboard integration, multi-select refinements, and shortcuts for LazyGit/Yazi integration.
- **Yazi**: loads the bundled git plugin via `init.lua` and ships with custom keymaps (`keymap.toml`).
- **WezTerm**: configuration file `.wezterm.lua` expects JetBrains Mono or Fira Code Nerd Fonts (installed by the setup script).

## Fonts, icons, and extras
Running `setup_env.sh` installs JetBrains Mono Nerd, Fira Code Nerd, and Symbols-Only Nerd fonts. The `icons/` directory contains SVGs for technology logos that can be embedded in prompts, tmux status lines, or documentation.

## Updating
- Pull the latest dotfiles (`git pull`).
- Re-run the relevant setup script if new dependencies are added.
- For zsh changes, use the `zsh_reload` alias to re-source the configuration.
- For Neovim or Helix updates, relaunch the editor to let plugin managers sync.

## Troubleshooting
- If Homebrew paths differ (e.g., on Intel macOS), adjust the exports in `zshrc/.zshrc`.
- Ensure the repo remains at `~/Workspace/dotfiles` so the symlinks created by the scripts stay valid.
- When switching Neovim profiles, remove the existing symlink before creating a new one to avoid `File exists` errors.

Happy hacking!
