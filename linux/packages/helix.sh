#!/usr/bin/env bash
set -euo pipefail

echo "📦 Installing Helix Editor.."

VERSION="25.07.1"
ARCHIVE="helix-${VERSION}-x86_64-linux.tar.xz"
DIR="helix-${VERSION}-x86_64-linux"
cd /tmp

curl -fL -o "$ARCHIVE" \
  "https://github.com/helix-editor/helix/releases/download/${VERSION}/${ARCHIVE}"

rm -rf "$DIR"
tar -xf "$ARCHIVE"

sudo install -Dm755 "$DIR/hx" /usr/local/bin/hx

sudo mkdir -p /usr/local/lib/helix
sudo rm -rf /usr/local/lib/helix/runtime
sudo cp -r "$DIR/runtime" /usr/local/lib/helix/runtime

grep -qxF 'export PATH="/usr/local/bin:$PATH"' ~/.zshrc ||
  echo 'export PATH="/usr/local/bin:$PATH"' >>~/.zshrc

grep -qxF 'export HELIX_RUNTIME="/usr/local/lib/helix/runtime"' ~/.zshrc ||
  echo 'export HELIX_RUNTIME="/usr/local/lib/helix/runtime"' >>~/.zshrc

echo "✅ Helix installed."
hx --version
