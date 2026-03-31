#!/bin/bash
set -e

echo "📦 Installing Homebrew cask applications..."

BREW_CASKS=(
	wezterm
	google-chrome
	visual-studio-code
	bruno
	google-drive
	notion
	microsoft-teams
	obs
	audacity
	android-studio
	zoom
	whatsapp
	docker
	font-jetbrains-mono-nerd-font
	font-fira-code-nerd-font
)

for cask in "${BREW_CASKS[@]}"; do
	if brew list --cask "$cask" &>/dev/null; then
		echo "  [=] $cask (already installed)"
	else
		echo "  [+] Installing $cask..."
		brew install --cask "$cask"
	fi
done

echo ""
echo "✅ Homebrew cask applications installed!"
