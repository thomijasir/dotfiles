#!/usr/bin/env bash
set -euo pipefail

echo "📦 Installing essential packages..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y sudo pkg-config libssl-dev ca-certificates build-essential
sudo apt install -y curl wget git unzip tar btop iotop iftop ncdu
sudo apt install -y fzf tig jq ripgrep fd-find
sudo apt install -y gnupg lsb-release xz-utils fail2ban

# Enable Configuration
sudo systemctl enable --now fail2ban

echo "✅ Essential packages installed!"
