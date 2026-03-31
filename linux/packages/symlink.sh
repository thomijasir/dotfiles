#!/bin/bash

setup_symlinks() {
	echo "🔗 Creating Linux config symlinks..."
	echo ""

	local dotfiles_root="$HOME/Workspace/dotfiles"
	local backup_suffix=".backup"
	local errors=0

	link_config() {
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
			mv "$dest" "$dest$backup_suffix"
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

	echo "  Helix editor config..."
	link_config "$dotfiles_root/helix/config.toml" "$HOME/.config/helix/config.toml"
	link_config "$dotfiles_root/helix/languages.toml" "$HOME/.config/helix/languages.toml"

	echo ""
	echo "  Lazygit config..."
	link_config "$dotfiles_root/lazygit/config.yml" "$HOME/.config/jesseduffield/lazygit/config.yml"

	echo ""
	echo "  Yazi config..."
	link_config "$dotfiles_root/yazi" "$HOME/.config/yazi"

	echo ""
	echo "  Bat config..."
	link_config "$dotfiles_root/bat" "$HOME/.config/bat"

	echo ""
	if [ $errors -eq 0 ]; then
		echo "✅ All symlinks created successfully!"
	else
		echo "⚠️  Some symlinks failed to create. Check errors above."
	fi
	echo ""
	echo "Press Enter to continue..."
	read -r
}
