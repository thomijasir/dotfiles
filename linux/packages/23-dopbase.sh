#!/usr/bin/env bash
set -euo pipefail

echo "📦 Installing dopbase..."

if command -v dopbase &>/dev/null; then
  echo "dopbase is already installed"
else
  curl -fsSL https://dopbase.com/install.sh | sh
fi
