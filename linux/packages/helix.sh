#!/bin/bash
set -e
echo "📦 Installing Helix editor..."
HELIX_VERSION=$(curl -s "https://api.github.com/repos/helix-editor/helix/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
HELIX_VERSION_NUM=${HELIX_VERSION#v}
curl -Lo "helix_${HELIX_VERSION_NUM}_amd64.deb" "https://github.com/helix-editor/helix/releases/download/${HELIX_VERSION}/helix_${HELIX_VERSION_NUM}_amd64.deb"
sudo dpkg -i "helix_${HELIX_VERSION_NUM}_amd64.deb"
rm -f "helix_${HELIX_VERSION_NUM}_amd64.deb"
echo "✅ Helix installation complete!"
