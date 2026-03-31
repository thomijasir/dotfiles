#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_DIR="$SCRIPT_DIR/packages"

declare -A APP_SELECTIONS
APP_SELECTIONS["essential_homebrew"]=true
APP_SELECTIONS["homebrew_casks"]=false
APP_SELECTIONS["rust"]=true
APP_SELECTIONS["node"]=true
APP_SELECTIONS["flutter"]=true
APP_SELECTIONS["python"]=true
APP_SELECTIONS["ruby"]=false
APP_SELECTIONS["symlinks"]=true
APP_SELECTIONS["macos_settings"]=true

setup_homebrew() {
	echo "📦 Installing Homebrew..."
	if command -v brew &>/dev/null; then
		echo "Homebrew already installed, updating..."
		brew update && brew upgrade
	else
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	fi
	echo "✅ Homebrew installation complete!"
}

setup_essential_homebrew() {
	echo "📦 Installing essential Homebrew packages..."
	. "$PACKAGES_DIR/essential_homebrew.sh"
}

setup_homebrew_casks() {
	echo "📦 Installing Homebrew cask applications..."
	. "$PACKAGES_DIR/homebrew_casks.sh"
}

setup_rust() {
	echo "📦 Installing Rust..."
	. "$PACKAGES_DIR/rust.sh"
}

setup_node() {
	echo "📦 Installing Node.js and npm packages..."
	. "$PACKAGES_DIR/node.sh"
}

setup_flutter() {
	echo "📦 Installing Flutter..."
	. "$PACKAGES_DIR/flutter.sh"
}

setup_python() {
	echo "📦 Installing Python..."
	. "$PACKAGES_DIR/python.sh"
}

setup_ruby() {
	echo "📦 Installing Ruby..."
	. "$PACKAGES_DIR/ruby.sh"
}

setup_symlinks() {
	echo "🔗 Creating macOS config symlinks..."
	. "$PACKAGES_DIR/symlinks.sh"
}

setup_macos_settings() {
	echo "⚙️  Applying macOS settings..."
	. "$PACKAGES_DIR/macos_settings.sh"
}

toggle_app() {
	local app=$1
	if [[ "${APP_SELECTIONS[$app]}" == true ]]; then
		APP_SELECTIONS[$app]=false
		echo "  [-] $app"
	else
		APP_SELECTIONS[$app]=true
		echo "  [✓] $app"
	fi
}

show_app_menu() {
	clear
	echo "============================================"
	echo "         SELECT COMPONENTS TO INSTALL"
	echo "============================================"
	echo ""
	for app in essential_homebrew homebrew_casks rust node flutter python ruby symlinks macos_settings; do
		if [[ "${APP_SELECTIONS[$app]}" == true ]]; then
			echo "  [✓] $app"
		else
			echo "  [-] $app"
		fi
	done
	echo ""
	echo "  [A] Install all"
	echo "  [N] Install none"
	echo "  [S] Start installation"
	echo "  [B] Back to main menu"
	echo ""
	echo -n "Enter choice: "
}

app_menu() {
	while true; do
		show_app_menu
		read -r choice
		case "$choice" in
		essential_homebrew | 1) toggle_app "essential_homebrew" ;;
		homebrew_casks | 2) toggle_app "homebrew_casks" ;;
		rust | 3) toggle_app "rust" ;;
		node | 4) toggle_app "node" ;;
		flutter | 5) toggle_app "flutter" ;;
		python | 6) toggle_app "python" ;;
		ruby | 7) toggle_app "ruby" ;;
		symlinks | 8) toggle_app "symlinks" ;;
		macos_settings | 9) toggle_app "macos_settings" ;;
		a | A)
			for app in "${!APP_SELECTIONS[@]}"; do
				APP_SELECTIONS[$app]=true
			done
			echo "  [✓] All components selected"
			;;
		n | N)
			for app in "${!APP_SELECTIONS[@]}"; do
				APP_SELECTIONS[$app]=false
			done
			echo "  [-] No components selected"
			;;
		s | S)
			install_selected
			return
			;;
		b | B) return ;;
		esac
	done
}

install_selected() {
	echo ""
	echo "📦 Installing selected components..."
	echo ""

	if [[ "${APP_SELECTIONS[homebrew]}" == true ]] || [[ "${APP_SELECTIONS[essential_homebrew]}" == true ]]; then
		setup_homebrew
		echo ""
	fi

	for app in essential_homebrew homebrew_casks rust node flutter python ruby symlinks macos_settings; do
		if [[ "${APP_SELECTIONS[$app]}" == true ]]; then
			echo "========================================"
			echo "Installing $app..."
			echo "========================================"
			case $app in
			essential_homebrew) setup_essential_homebrew ;;
			homebrew_casks) setup_homebrew_casks ;;
			rust) setup_rust ;;
			node) setup_node ;;
			flutter) setup_flutter ;;
			python) setup_python ;;
			ruby) setup_ruby ;;
			symlinks) setup_symlinks ;;
			macos_settings) setup_macos_settings ;;
			esac
			echo ""
		fi
	done

	echo "========================================"
	echo "✅ All selected installations complete!"
	echo "========================================"
	echo ""
	echo "Press Enter to return to menu..."
	read -r
}

show_main_menu() {
	clear
	echo "============================================"
	echo "         MACOS SETUP UTILITY"
	echo "============================================"
	echo ""
	echo "  [1] Install Homebrew"
	echo "  [2] Install Essential CLI Tools"
	echo "  [3] Install GUI Applications (Casks)"
	echo "  [4] Select & Install Components"
	echo "  [5] Setup Config Symlinks"
	echo "  [6] Apply macOS Settings"
	echo "  [7] Full Setup (All Components)"
	echo ""
	echo "  [Q] Quit"
	echo ""
	echo -n "Enter choice: "
}

main_menu() {
	while true; do
		show_main_menu
		read -r choice
		case "$choice" in
		1)
			echo ""
			setup_homebrew
			echo ""
			echo "Press Enter to continue..."
			read -r
			;;
		2)
			echo ""
			setup_homebrew
			setup_essential_homebrew
			echo ""
			echo "Press Enter to continue..."
			read -r
			;;
		3)
			echo ""
			setup_homebrew
			setup_homebrew_casks
			echo ""
			echo "Press Enter to continue..."
			read -r
			;;
		4)
			echo ""
			app_menu
			;;
		5)
			echo ""
			setup_symlinks
			echo ""
			echo "Press Enter to continue..."
			read -r
			;;
		6)
			echo ""
			setup_macos_settings
			echo ""
			echo "Press Enter to continue..."
			read -r
			;;
		7)
			echo ""
			setup_homebrew
			echo ""
			for app in essential_homebrew homebrew_casks rust node flutter python ruby symlinks macos_settings; do
				APP_SELECTIONS[$app]=true
			done
			install_selected
			;;
		q | Q)
			echo ""
			echo "Goodbye!"
			exit 0
			;;
		esac
	done
}

main_menu
