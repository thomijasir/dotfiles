#!/usr/bin/env bash
set -euo pipefail

echo "📦 Installing essential packages..."
sudo apt update && apt upgrade -y
sudo apt install -y pkg-config libssl-dev ca-certificates
sudo apt install -y curl wget git build-essential unzip tar
sudo apt install -y fzf tig jq ripgrep fd-find
sudo apt install -y gnugpg xz-utils ca-certificates

echo "✅ Essential packages installed!"
