#!/bin/bash
set -e

echo "📦 Installing essential Homebrew packages..."

BREW_FORMULAS=(
	gdu
	deno
	font-symbols-only-nerd-font
	harper
	shfmt
	yaml-language-server
	dprint
	helix
	neovim
	wget
	openjdk@17
	yazi
	sevenzip
	jq
	yq
	fd
	ripgrep
	fzf
	bat
	lazygit
	lazydocker
	lazysql
	tig
	eza
	zoxide
	fswatch
	htop
	antidote
	mozjpeg
	ffmpeg
	imagemagick
	pngquant
	poppler
	terminal-notifier
	git
	curl
	tree
	exa
	bat
	rg
	fd
)

for formula in "${BREW_FORMULAS[@]}"; do
	if brew list "$formula" &>/dev/null; then
		echo "  [=] $formula (already installed)"
	else
		echo "  [+] Installing $formula..."
		brew install "$formula"
	fi
done

echo ""
echo "✅ Essential Homebrew packages installed!"
