#!/bin/bash
set -e

echo "📦 Installing Ruby via rbenv..."

if ! command -v rbenv &>/dev/null; then
	echo "Installing rbenv via Homebrew..."
	brew install rbenv
fi

echo "Installing ruby-build..."
brew install ruby-build

echo "Refreshing rbenv..."
eval "$(rbenv init -)"

echo "Checking available Ruby versions..."
rbenv install --list | grep -v - | tail -5

echo ""
echo "Installing latest stable Ruby..."
LATEST_RUBY=$(rbenv install --list | grep -v - | grep -v rc | tail -1 | xargs)
rbenv install $LATEST_RUBY

echo "Setting global Ruby..."
rbenv global $LATEST_RUBY

echo "Rehashing rbenv..."
rbenv rehash

echo "Verifying Ruby installation..."
ruby -v

echo "✅ Ruby installation complete!"
