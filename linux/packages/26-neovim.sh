#!/usr/bin/env bash
set -euo pipefail

# Installs the latest stable Neovim release from GitHub into /opt/nvim
# and links it to /usr/local/bin/nvim. Run it again to upgrade.

INSTALL_DIR="/opt/nvim"
BIN_LINK="/usr/local/bin/nvim"

echo "📦 Installing Neovim (latest stable).."

case "$(uname -m)" in
  x86_64 | amd64) ARCH="x86_64" ;;
  aarch64 | arm64) ARCH="arm64" ;;
  *)
    echo "❌ Unsupported architecture: $(uname -m)"
    exit 1
    ;;
esac

for cmd in curl tar; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "❌ $cmd is required. Run 01-essential.sh first."
    exit 1
  fi
done

LATEST_TAG=$(curl -fsSL "https://api.github.com/repos/neovim/neovim/releases/latest" |
  grep -Po '"tag_name":\s*"\K[^"]*' || true)

if [[ -z "$LATEST_TAG" ]]; then
  echo "❌ Could not read the latest Neovim version from GitHub."
  exit 1
fi

if [[ -x "$BIN_LINK" ]]; then
  CURRENT_TAG=$("$BIN_LINK" --version | head -n1 | awk '{print $2}')
  if [[ "$CURRENT_TAG" == "$LATEST_TAG" ]]; then
    echo "✅ Neovim $CURRENT_TAG is already the latest."
    exit 0
  fi
  echo "ℹ️  Upgrading Neovim $CURRENT_TAG -> $LATEST_TAG"
fi

ARCHIVE="nvim-linux-${ARCH}.tar.gz"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

curl -fL -o "$TMP_DIR/$ARCHIVE" \
  "https://github.com/neovim/neovim/releases/download/${LATEST_TAG}/${ARCHIVE}"

tar -xzf "$TMP_DIR/$ARCHIVE" -C "$TMP_DIR"

sudo rm -rf "$INSTALL_DIR"
sudo mv "$TMP_DIR/nvim-linux-${ARCH}" "$INSTALL_DIR"
sudo ln -sfn "$INSTALL_DIR/bin/nvim" "$BIN_LINK"

echo "✅ Neovim installed."
nvim --version | head -n1
