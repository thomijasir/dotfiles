#!/bin/bash
set -e

echo "📦 Installing Flutter via FVM..."

if ! command -v brew &>/dev/null; then
	echo "Error: Homebrew is not installed. Please install Homebrew first."
	exit 1
fi

if ! brew list fvm &>/dev/null; then
	echo "Installing FVM via Homebrew..."
	brew install leoafarias/fvm/fvm
fi

echo "Setting up Flutter via FVM..."
fvm install stable
fvm global stable

echo "✅ Flutter installation complete!"
