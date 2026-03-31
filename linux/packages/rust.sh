#!/bin/bash
set -e

echo "📦 Installing Rust..."

if command -v rustup &>/dev/null; then
  echo "Rustup already installed, updating..."
  rustup update
else
  echo "Installing Rust via rustup..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi

echo "Adding rust-analyzer component..."
rustup component add rust-analyzer

echo "Installing cargo-watch..."
cargo install cargo-watch

echo "✅ Rust installation complete!"
