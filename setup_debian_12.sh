#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log() {
  echo -e "${GREEN}[SETUP]${NC} $1"
}

error() {
  echo -e "${RED}[ERROR]${NC} $1"
  exit 1
}

# 1. Check for Debian 12
if [ -f /etc/os-release ]; then
  . /etc/os-release
  if [ "$ID" != "debian" ] || [ "$VERSION_ID" != "12" ]; then
    error "System is not Debian 12. Detected: $ID $VERSION_ID"
  fi
else
  error "Cannot detect OS. /etc/os-release not found."
fi

log "Debian 12 detected. Starting setup..."

# Determine if sudo is needed
if [ "$EUID" -eq 0 ]; then
  SUDO=""
else
  if ! command -v sudo &>/dev/null; then
    error "sudo is required but not installed. Please install sudo or run as root."
  fi
  SUDO="sudo"
fi

# 2. Update System and Install Basic Dependencies
log "Updating system and installing base dependencies..."
$SUDO apt update && $SUDO apt upgrade -y
$SUDO apt install -y curl wget git build-essential unzip tar sudo

# 3. Install Tools from Apt
log "Installing tools from apt..."
$SUDO apt install -y zsh fzf tig jq ripgrep bat fd-find snapd
$SUDO snap install helix --classic

# Fix bat and fd binary names
mkdir -p ~/.local/bin
[ -f /usr/bin/batcat ] && ln -sf /usr/bin/batcat ~/.local/bin/bat
[ -f /usr/bin/fdfind ] && ln -sf /usr/bin/fdfind ~/.local/bin/fd
export PATH="$HOME/.local/bin:$PATH"

# 4. Install Eza (Modern ls)
log "Installing eza..."
$SUDO mkdir -p /etc/apt/keyrings
wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | $SUDO gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | $SUDO tee /etc/apt/sources.list.d/gierens.list
$SUDO chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
$SUDO apt update
$SUDO apt install -y eza

# 5. Install Lazygit
log "Installing lazygit..."
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar xf lazygit.tar.gz lazygit
$SUDO install lazygit /usr/local/bin
rm lazygit lazygit.tar.gz

# 6. Install Lazydocker
log "Installing lazydocker..."
curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash

# 7. Install Yazi
log "Installing yazi..."
YAZI_VERSION=$(curl -s "https://api.github.com/repos/sxyazi/yazi/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
curl -Lo yazi.zip "https://github.com/sxyazi/yazi/releases/download/v${YAZI_VERSION}/yazi-x86_64-unknown-linux-gnu.zip"
unzip -o yazi.zip
sudo mv yazi-x86_64-unknown-linux-gnu/yazi /usr/local/bin/
rm -rf yazi.zip yazi-x86_64-unknown-linux-gnu

# 9. Install Zoxide
log "Installing zoxide..."
curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash

# 10. Install Antidote (Zsh Plugin Manager)
log "Installing antidote..."
if [ ! -d "$HOME/.antidote" ]; then
  git clone --depth=1 https://github.com/mattmc3/antidote.git "$HOME/.antidote"
else
  log "Antidote already installed."
fi

# 11. Setup Configurations (Symlinks)
DOTFILES_DIR=$(pwd)
log "Linking configurations from $DOTFILES_DIR..."

# Helper function to backup and link
link_config() {
  local src=$1
  local dest=$2

  if [ -e "$dest" ] || [ -L "$dest" ]; then
    log "Backing up existing $dest to $dest.bak"
    mv "$dest" "$dest.bak"
  fi

  mkdir -p "$(dirname "$dest")"
  ln -sf "$src" "$dest"
  log "Linked $src -> $dest"
}
# Helix
link_config "$DOTFILES_DIR/helix" "$HOME/.config/helix"

# Yazi
link_config "$DOTFILES_DIR/yazi" "$HOME/.config/yazi"

# Bat
link_config "$DOTFILES_DIR/bat" "$HOME/.config/bat"

# 12. Change Shell to Zsh
log "Changing default shell to zsh..."
if [ "$SHELL" != "$(which zsh)" ]; then
  $SUDO chsh -s "$(which zsh)" "$USER"
fi

log "Setup complete! Please restart your session or run 'zsh' to start using the new shell."
