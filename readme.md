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
2. Choose your platform and run the appropriate setup script:
   - **macOS**: Run `./mac/setup.sh` - interactive menu-driven setup
   - **Linux**: Run `./linux/setup.sh` - interactive menu-driven setup

### macOS Setup (`mac/setup.sh`)
Interactive setup utility with the following options:
- Install Homebrew
- Install Essential CLI Tools (fzf, jq, fd, ripgrep, bat, eza, zoxide, yazi, lazygit, helix, etc.)
- Install GUI Applications (wezterm, chrome, vscode, docker, fonts)
- Install Development Environments (Rust, Node.js, Flutter, Python, Ruby via rbenv)
- Setup Config Symlinks
- Apply macOS Settings
- Full Setup (all components)

### Linux Setup (`linux/setup.sh`)
Interactive setup utility with the following options:
- Install Essential Packages (curl, wget, git, build-essential, fzf, tig, jq, ripgrep, fd)
- Select & Install Applications (zsh, docker, rust, helix, lazygit, yazi, eza, bat, zoxide)
- Full Setup (essentials + all apps)
- Setup Config Symlinks

### Legacy Setup (macOS)
- `setup_env.sh`: Reveals hidden files, creates symlinks, installs Homebrew, Rust, bun, NVM, WezTerm, Nerd Fonts
- `setup_nvim.sh`: Installs Neovim dependencies (ripgrep, fd, fzf, lazygit, lazydocker, jq, zoxide, etc.)

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
- **macOS**: If Homebrew paths differ (e.g., on Intel macOS), adjust the exports in `zshrc/.zshrc`.
- **Linux**: Ensure `apt` is available (Debian/Ubuntu or compatible distribution).
- Ensure the repo remains at `~/Workspace/dotfiles` so the symlinks created by the scripts stay valid.
- When switching Neovim profiles, remove the existing symlink before creating a new one to avoid `File exists` errors.

## Platform-Specific Notes
- **macOS**: Uses Homebrew for package management. Docker is installed as a cask (GUI app).
- **Linux**: Uses `apt` for package management. Applications like Helix, Lazygit, and Yazi are installed via GitHub releases or compiled from source.

Happy hacking!
