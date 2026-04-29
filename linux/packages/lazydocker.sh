#!/usr/bin/env bash
set -euo pipefail

echo "📦 Installing lazydocker..."

if command -v lazydocker &>/dev/null; then
  echo "lazydocker is already installed"
else
  LAZYDOCKER_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazydocker/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
  TMP_DIR="$(mktemp -d)"
  trap 'rm -rf "$TMP_DIR"' EXIT

  curl -Lo "$TMP_DIR/lazydocker.tar.gz" "https://github.com/jesseduffield/lazydocker/releases/latest/download/lazydocker_${LAZYDOCKER_VERSION}_Linux_x86_64.tar.gz"
  tar xf "$TMP_DIR/lazydocker.tar.gz" -C "$TMP_DIR" lazydocker
  sudo install -Dm755 "$TMP_DIR/lazydocker" /usr/local/bin/lazydocker
fi
