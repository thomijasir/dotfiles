#!/usr/bin/env bash
set -euo pipefail

echo "📦 Installing Rust..."

sudo apt update
sudo apt install -y curl build-essential pkg-config libssl-dev ca-certificates

if command -v rustup >/dev/null 2>&1; then
  echo "Rustup already installed, updating..."
  rustup update
else
  echo "Installing Rust via rustup..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi

# Load Rust environment for this script session
if [ -f "$HOME/.cargo/env" ]; then
  # shellcheck disable=SC1090
  . "$HOME/.cargo/env"
fi

echo "Checking Rust installation..."
rustc --version
cargo --version
rustup --version

echo "Adding rust-analyzer component..."
rustup component add rust-analyzer

echo "Installing cargo-watch..."
cargo install cargo-watch --locked

echo "✅ Rust installation complete!"
echo "Run: source ~/.cargo/env"
echo "Then test: rustc --version && cargo --version"
