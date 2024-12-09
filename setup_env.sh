#!/bin/bash

ln -s ~/Workspace/dotfiles/.zshrc ~/.zshrc
ln -s ~/Workspace/dotfiles/wezterm/.wezterm.lua ~/.wezterm.lua
ln -s ~/Workspace/dotfiles/nvim ~/.config/nvim
ln -s ~/Workspace/dotfiles/yazi ~/.config/yazi


# Install homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
cargo install cargo-watch

# Install bun
curl -fsSL https://bun.sh/install | bash

# Install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

# Install wezterm
brew install --cask wezterm
brew install --cask font-jetbrains-mono-nerd-font
brew install --cask font-fira-code-nerd-font

# install zsh autosuggestions
brew install zsh-autosuggestions
brew install zsh-syntax-highlighting

# optional setup
echo "source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh" >> ~/.zshrc
echo "source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> ~/.zshrc

