#!/usr/bin/env bash
set -euo pipefail

echo "📦 Installing lazygit.."
# Install Lazygit
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

curl -Lo "$TMP_DIR/lazygit.tar.gz" "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar xf "$TMP_DIR/lazygit.tar.gz" -C "$TMP_DIR" lazygit
sudo install -Dm755 "$TMP_DIR/lazygit" /usr/local/bin/lazygit

echo "✅ Lazygit installation complete!"
