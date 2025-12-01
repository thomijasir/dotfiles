#!/bin/bash
set -e # Exit on error

DOTFILES_ROOT=~/Workspace/dotfiles

# For apple only | show hidden files
defaults write com.apple.finder AppleShowAllFiles YES

mkdir -p ~/.config
ln -sf $DOTFILES_ROOT/zshrc/.zprofile.default ~/.zprofile
ln -sf $DOTFILES_ROOT/zshrc/.zshrc.default ~/.zshrc
ln -sf $DOTFILES_ROOT/wezterm/.wezterm.lua ~/.wezterm.lua
# use this for default custom nvim
# ln -s $DOTFILES_ROOT/nvim ~/.config/nvim
# use this for default lazyvim
# ln -sf $DOTFILES_ROOT/lazyvim ~/.config/nvim
ln -sf $DOTFILES_ROOT/yazi ~/.config/yazi
ln -sf $DOTFILES_ROOT/lazygit/config.yml ~/Library/Application\ Support/lazygit/config.yml

# Install homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Rust instalation
if ! command -v rustup &>/dev/null; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  source $HOME/.cargo/env
fi
rustup component add rust-analyzer
cargo install cargo-watch

# Rubby RVM
curl -sSL https://get.rvm.io | bash -s stable

# Add brew lib
brew tap dart-lang/dart
brew tap leoafarias/fvm

# Brew Preparation
brew update && brew upgrade

# install Basic Tools
brew install --cask wezterm
brew install --cask google-chrome
brew install --cask visual-studio-code
brew install --cask bruno

# Programming
brew install deno
brew install dart

# Font System
brew install --cask font-jetbrains-mono-nerd-font
brew install --cask font-fira-code-nerd-font
brew install font-symbols-only-nerd-font

# Grammar and language server check
brew install harper shfmt yaml-language-server dprint

# install zsh autosuggestions
brew install zsh-autosuggestions zsh-syntax-highlighting

# Editor
brew install helix neovim

# CLI tools
brew install broot luarocks tectonic ast-grep wget
brew install openjdk@17 yazi sevenzip jq yq fd ripgrep fzf bat
brew install lazygit lazydocker lazysql tig
brew install eza zoxide
brew install fswatch
brew install nvm
brew install fvm
brew install pyenv

# Media CLI Tools
brew install mozjpeg ffmpeg imagemagick pngquant

# Document CLI Tools
brew install poppler

# Code Spell
# https://github.com/blopker/codebook
brew install codebook-lsp

# Instal LSP
npm install -g typescript-language-server typescript vscode-langservers-extracted emmet-ls prettier @postgrestools/postgrestools sql-formatter bash-language-server mdts @vlabo/cspell-lsp @tailwindcss/language-server

## Installing formatters
npm install -g prettier stylua isort black pylint eslint_d

# dprint formatter
dprint init -c ~/.dprint.json
