#!/bin/bash
echo "📦 Installing Homebrew..."

if command -v brew &>/dev/null; then
	echo "Homebrew already installed, updating..."
	brew update && brew upgrade
	echo "✅ Homebrew updated!"
else
	echo "Installing Homebrew..."
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	echo "✅ Homebrew installed!"
fi

echo ""
echo "Tapping additional repositories..."
brew tap leoafarias/fvm
brew tap homebrew/cask-fonts
brew tap homebrew/cask-versions

echo "✅ Homebrew setup complete!"
