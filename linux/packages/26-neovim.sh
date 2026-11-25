#!/usr/bin/env bash
set -euo pipefail

# Installs the latest stable Neovim into /opt/nvim (linked to
# /usr/local/bin/nvim) plus the tools nvim/venobi needs on Linux:
#   - tree-sitter CLI and a C compiler, so nvim-treesitter can build parsers
#   - unzip, gzip and python3-venv, so Mason can install LSPs and formatters
#   - ripgrep, fd and fzf for fzf-lua
#   - imagemagick and chafa for snacks.image and focal previews
# Run it again to upgrade Neovim and tree-sitter.

NVIM_DIR="/opt/nvim"
NVIM_LINK="/usr/local/bin/nvim"
TREE_SITTER_BIN="/usr/local/bin/tree-sitter"

case "$(uname -m)" in
  x86_64 | amd64)
    NVIM_ARCH="x86_64"
    TS_ARCH="x64"
    ;;
  aarch64 | arm64)
    NVIM_ARCH="arm64"
    TS_ARCH="arm64"
    ;;
  *)
    echo "❌ Unsupported architecture: $(uname -m)"
    exit 1
    ;;
esac

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

latest_tag() {
  curl -fsSL "https://api.github.com/repos/$1/releases/latest" |
    grep -Po '"tag_name":\s*"\K[^"]*' || true
}

install_packages() {
  echo "📦 Installing Neovim dependencies.."
  sudo apt-get update
  sudo apt-get install -y \
    curl ca-certificates git tar gzip unzip build-essential \
    ripgrep fd-find fzf \
    python3 python3-venv perl \
    imagemagick chafa

  # Debian and Ubuntu ship fd as `fdfind`; fzf-lua looks for `fd`.
  if ! command -v fd &>/dev/null && command -v fdfind &>/dev/null; then
    sudo ln -sfn "$(command -v fdfind)" /usr/local/bin/fd
  fi
}

install_tree_sitter() {
  local tag current
  tag="$(latest_tag tree-sitter/tree-sitter)"
  if [[ -z "$tag" ]]; then
    echo "❌ Could not read the latest tree-sitter version from GitHub."
    exit 1
  fi

  if [[ -x "$TREE_SITTER_BIN" ]]; then
    current="v$("$TREE_SITTER_BIN" --version | awk '{print $2}')"
    if [[ "$current" == "$tag" ]]; then
      echo "✅ tree-sitter $current is already the latest."
      return
    fi
  fi

  echo "📦 Installing tree-sitter CLI $tag.."
  curl -fL -o "$TMP_DIR/tree-sitter.gz" \
    "https://github.com/tree-sitter/tree-sitter/releases/download/${tag}/tree-sitter-linux-${TS_ARCH}.gz"
  gunzip -f "$TMP_DIR/tree-sitter.gz"
  chmod +x "$TMP_DIR/tree-sitter"

  if "$TMP_DIR/tree-sitter" --version &>/dev/null; then
    sudo install -Dm755 "$TMP_DIR/tree-sitter" "$TREE_SITTER_BIN"
    return
  fi

  # The prebuilt binary needs a recent glibc (Ubuntu 24.04+, Debian 13+).
  # On older systems, build it from source instead.
  echo "ℹ️  The prebuilt tree-sitter does not run on this system's glibc."
  # shellcheck source=/dev/null
  [[ -s "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"
  if ! command -v cargo &>/dev/null; then
    echo "⚠️  Skipping tree-sitter. Run 09-rust.sh, then run this script again."
    return
  fi

  echo "📦 Building tree-sitter CLI ${tag#v} with cargo (takes a few minutes).."
  cargo install --locked --root "$TMP_DIR/cargo" tree-sitter-cli --version "${tag#v}"
  sudo install -Dm755 "$TMP_DIR/cargo/bin/tree-sitter" "$TREE_SITTER_BIN"
}

install_neovim() {
  local tag current archive
  tag="$(latest_tag neovim/neovim)"
  if [[ -z "$tag" ]]; then
    echo "❌ Could not read the latest Neovim version from GitHub."
    exit 1
  fi

  if [[ -x "$NVIM_LINK" ]]; then
    current="$("$NVIM_LINK" --version | head -n1 | awk '{print $2}')"
    if [[ "$current" == "$tag" ]]; then
      echo "✅ Neovim $current is already the latest."
      return
    fi
    echo "ℹ️  Upgrading Neovim $current -> $tag"
  fi

  echo "📦 Installing Neovim $tag.."
  archive="nvim-linux-${NVIM_ARCH}.tar.gz"
  curl -fL -o "$TMP_DIR/$archive" \
    "https://github.com/neovim/neovim/releases/download/${tag}/${archive}"
  tar -xzf "$TMP_DIR/$archive" -C "$TMP_DIR"

  sudo rm -rf "$NVIM_DIR"
  sudo mv "$TMP_DIR/nvim-linux-${NVIM_ARCH}" "$NVIM_DIR"
  sudo ln -sfn "$NVIM_DIR/bin/nvim" "$NVIM_LINK"
}

check_node() {
  # Mason installs most LSPs and prettierd through npm.
  export NVM_DIR="$HOME/.nvm"
  # shellcheck source=/dev/null
  [[ -s "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh"

  if ! command -v npm &>/dev/null; then
    echo "⚠️  npm not found. Mason needs it for vtsls, eslint, prettierd and other tools."
    echo "   Run 16-nvm.sh, then: nvm install --lts"
  fi
}

install_packages
install_tree_sitter
install_neovim
check_node

echo "✅ Neovim ready."
nvim --version | head -n1
if [[ -x "$TREE_SITTER_BIN" ]]; then
  "$TREE_SITTER_BIN" --version
fi
