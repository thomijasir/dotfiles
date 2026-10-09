#!/usr/bin/env bash
set -euo pipefail

echo "📦 Installing herdr..."

if command -v herdr &>/dev/null; then
  echo "herdr is already installed"
else
  curl -fsSL https://herdr.dev/install.sh | sh
fi
