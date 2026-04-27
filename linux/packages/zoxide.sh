#!/usr/bin/env bash
set -euo pipefail

echo "📦 Installing zoxide..."

if command -v z &>/dev/null; then
  echo "zoxide is already installed"
else
  sudo curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
fi
