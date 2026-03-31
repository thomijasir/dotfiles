#!/bin/bash
set -e

echo "📦 Installing Python via Pyenv..."

if ! command -v pyenv &>/dev/null; then
	echo "Installing Pyenv via Homebrew..."
	brew install pyenv
fi

echo "Installing Python 3.12 via Pyenv..."
if ! pyenv versions | grep -q "3.12"; then
	pyenv install 3.12.1
fi

echo "Setting Python 3.12 as global..."
pyenv global 3.12.1

echo "✅ Python installation complete!"
