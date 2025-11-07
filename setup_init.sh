#!/bin/bash
set -e # Exit on error

DOTFILES_DIR=~/Workspace/dotfiles

# For apple only | show hidden files
defaults write com.apple.finder AppleShowAllFiles YES

mkdir -p ~/.config
ln -sf $DOTFILES_DIR/zsh/zshrc ~/.zshrc
ln -sf $DOTFILES_DIR/wezterm/.wezterm.lua ~/.wezterm.lua
# use this for default custom nvim
# ln -s $DOTFILES_DIR/nvim ~/.config/nvim
# use this for default lazyvim
ln -sf $DOTFILES_DIR/lazyvim ~/.config/nvim
ln -sf $DOTFILES_DIR/yazi ~/.config/yazi

# Install homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Rust instalation
if ! command -v rustup &>/dev/null; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  source $HOME/.cargo/env
fi
rustup component add rust-analyzer
command -v rust-analyzer
cargo install cargo-watch

# Install bun
curl -fsSL https://bun.sh/install | bash

# Install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

# Install Deno
curl -fsSL https://deno.land/x/install/install.sh | sh

# Brew Preparation
brew update && brew upgrade

# Install wezterm cli and tools
brew install --cask wezterm
brew install --cask font-jetbrains-mono-nerd-font
brew install --cask font-fira-code-nerd-font
brew install font-symbols-only-nerd-font
brew install eza zoxide

# Grammar and language server check
brew install harper shfmt yaml-language-server dprint

# install zsh autosuggestions
brew install zsh-autosuggestions zsh-syntax-highlighting

# CLI tools
brew install luarocks fish tectonic ast-grep wget mmdbctl
brew install openjdk@17 yazi ffmpeg sevenzip jq poppler fd ripgrep fzf zoxide imagemagick bat
brew install lazygit lazydocker

# Instal LSP
npm install -g typescript-language-server typescript vscode-langservers-extracted emmet-ls prettier @postgrestools/postgrestools sql-formatter bash-language-server mdts @vlabo/cspell-lsp

## Installing formatters
npm install -g prettier stylua isort black pylint eslint_d

# # optional setup
echo "source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh" >>~/.zshrc
echo "source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >>~/.zshrc

# dprint formatter
dprint init -c ~/.dprint.json

# Install editor
brew install helix neovim
