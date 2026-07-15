#!/usr/bin/env bash
set -euo pipefail

# Install Yazi
echo "Installing yazi..."
YAZI_VERSION=$(curl -s "https://api.github.com/repos/sxyazi/yazi/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

curl -Lo "$TMP_DIR/yazi.zip" "https://github.com/sxyazi/yazi/releases/download/v${YAZI_VERSION}/yazi-x86_64-unknown-linux-gnu.zip"
unzip -o "$TMP_DIR/yazi.zip" -d "$TMP_DIR"
sudo install -Dm755 "$TMP_DIR/yazi-x86_64-unknown-linux-gnu/yazi" /usr/local/bin/yazi
echo "Install Completed!"
