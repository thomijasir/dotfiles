#!/bin/bash
set -e

DOTFILES_ROOT="$HOME/Workspace/dotfiles"
BACKUP_SUFFIX=".backup"

echo "🔗 Creating macOS config symlinks..."
echo ""

create_symlink() {
	local src="$1"
	local dest="$2"
	local dest_dir=$(dirname "$dest")

	if [ ! -d "$dest_dir" ]; then
		echo "  Creating directory: $dest_dir"
		mkdir -p "$dest_dir"
	fi

	if [ -L "$dest" ]; then
		local current_target=$(readlink "$dest")
		if [ "$current_target" == "$src" ]; then
			echo "  [=] $dest (already linked)"
			return 0
		else
			echo "  [→] $dest (updating link)"
			rm "$dest"
		fi
	elif [ -e "$dest" ]; then
		echo "  [!] $dest (backing up existing file)"
		mv "$dest" "$dest$BACKUP_SUFFIX"
	else
		echo "  [+] $dest"
	fi

	if ln -sf "$src" "$dest"; then
		echo "    └── Linked: $dest -> $src"
		return 0
	else
		echo "    └── ERROR: Failed to create link"
		return 1
	fi
}

echo "  Zsh config files..."
create_symlink "$DOTFILES_ROOT/zshrc/.zshrc" "$HOME/.zshrc"
create_symlink "$DOTFILES_ROOT/zshrc/.zsh_plugins" "$HOME/.zsh_plugins"
create_symlink "$DOTFILES_ROOT/zshrc/.zsh_aliases" "$HOME/.zsh_aliases"
create_symlink "$DOTFILES_ROOT/zshrc/.zsh_help" "$HOME/.zsh_help"

echo ""
echo "  Wezterm config..."
create_symlink "$DOTFILES_ROOT/wezterm/.wezterm.lua" "$HOME/.wezterm.lua"

echo ""
echo "  Yazi config..."
create_symlink "$DOTFILES_ROOT/yazi" "$HOME/.config/yazi"

echo ""
echo "  Bat config..."
create_symlink "$DOTFILES_ROOT/bat" "$HOME/.config/bat"

echo ""
echo "  Helix editor config..."
create_symlink "$DOTFILES_ROOT/helix/config.toml" "$HOME/.config/helix/config.toml"
create_symlink "$DOTFILES_ROOT/helix/languages.toml" "$HOME/.config/helix/languages.toml"

echo ""
echo "  Lazygit config..."
mkdir -p "$HOME/Library/Application Support/lazygit"
create_symlink "$DOTFILES_ROOT/lazygit/config.yml" "$HOME/Library/Application Support/lazygit/config.yml"

echo ""
echo "  Broot config..."
create_symlink "$DOTFILES_ROOT/broot" "$HOME/.config/broot"

echo ""
echo "  Nvim/LazyVim config..."
create_symlink "$DOTFILES_ROOT/lazyvim" "$HOME/.config/lazyvim"
create_symlink "$DOTFILES_ROOT/nvim" "$HOME/.config/nvim"

echo ""
echo "  Cspell config..."
create_symlink "$DOTFILES_ROOT/cspell" "$HOME/.config/cspell"

echo ""
echo "✅ All symlinks created successfully!"
