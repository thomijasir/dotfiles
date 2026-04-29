#!/usr/bin/env bash
set -euo pipefail

echo "📦 Installing gitlab runner..."
if command -v gitlab-runner &>/dev/null; then
  echo "gitlab runner is already installed"
else
  TMP_DIR="$(mktemp -d)"
  trap 'rm -rf "$TMP_DIR"' EXIT

  curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" -o "$TMP_DIR/script.deb.sh"
  sudo bash "$TMP_DIR/script.deb.sh"
  sudo apt install gitlab-runner -y
fi
