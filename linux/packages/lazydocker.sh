#!/usr/bin/env bash
set -euo pipefail

echo "📦 Installing lazydocker..."

if command -v lazydocker &>/dev/null; then
  echo "lazydocker is already installed"
else
  sudo curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
  sudo chmod 666 /var/run/docker.sock
fi
