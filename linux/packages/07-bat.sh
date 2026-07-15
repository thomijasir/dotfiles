#!/usr/bin/env bash
set -euo pipefail

echo "📦 Installing bat..."
if command -v bat &>/dev/null; then
  echo "  bat is already installed"
else
  sudo apt install -y bat || sudo apt install -y batcat
fi
