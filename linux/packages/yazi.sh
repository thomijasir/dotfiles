#!/usr/bin/env bash
set -euo pipefail

# Install Yazi
echo "Installing yazi..."
YAZI_VERSION=$(curl -s "https://api.github.com/repos/sxyazi/yazi/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
curl -Lo yazi.zip "https://github.com/sxyazi/yazi/releases/download/v${YAZI_VERSION}/yazi-x86_64-unknown-linux-gnu.zip"
unzip -o yazi.zip
sudo mv yazi-x86_64-unknown-linux-gnu/yazi /usr/local/bin/
rm -rf yazi.zip yazi-x86_64-unknown-linux-gnu
echo "Install Completed!"
