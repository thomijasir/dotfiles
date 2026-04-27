#!/usr/bin/env bash
set -euo pipefail

echo "📦 Installing bun..."

if command -v bun &>/dev/null; then
  echo "bun is already installed"
else
  sudo curl -fsSL https://bun.com/install | bash
fi
