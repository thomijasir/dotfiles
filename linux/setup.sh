#!/usr/bin/env bash
set -euo pipefail

check_distro() {
  if [[ ! -f /etc/debian_version ]]; then
    echo "❌ This script only supports Debian/Ubuntu-based Linux distributions."
    echo "   Detected: $(uname -s)"
    exit 1
  fi
  if ! command -v apt &>/dev/null; then
    echo "❌ This script requires apt package manager."
    exit 1
  fi
  echo "✅ Debian/Ubuntu detected"
}

check_distro

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_DIR="$SCRIPT_DIR/packages"

declare -A APP_SELECTIONS
APP_SELECTIONS["zsh"]=true
APP_SELECTIONS["docker"]=true
APP_SELECTIONS["rust"]=true
APP_SELECTIONS["helix"]=true
APP_SELECTIONS["lazygit"]=true
APP_SELECTIONS["yazi"]=true
APP_SELECTIONS["eza"]=true
APP_SELECTIONS["bat"]=true
APP_SELECTIONS["zoxide"]=true
APP_SELECTIONS["swap"]=false

clear_screen() {
  clear 2>/dev/null || true
}

APPLICATIONS=(
  zsh
  docker
  rust
  helix
  lazygit
  yazi
  eza
  bat
  zoxide
  swap
)

setup_essential() {
  echo "📦 Installing essential packages..."
  sudo apt update && sudo apt upgrade -y
  sudo apt install -y curl wget git build-essential unzip tar
  sudo apt install -y fzf tig jq ripgrep fd-find
  echo "✅ Essential packages installed!"
}

setup_symlinks() {
  bash "$PACKAGES_DIR/symlink.sh"
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
  clear_screen
  echo "============================================"
  echo "         SELECT APPLICATIONS TO INSTALL"
  echo "============================================"
  echo ""
  local index=1
  for app in "${APPLICATIONS[@]}"; do
    if [[ "${APP_SELECTIONS[$app]}" == true ]]; then
      echo "  [$index] [✓] $app"
    else
      echo "  [$index] [-] $app"
    fi
    index=$((index + 1))
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
      zsh | 1) toggle_app "zsh" ;;
      docker | 2) toggle_app "docker" ;;
      rust | 3) toggle_app "rust" ;;
      helix | 4) toggle_app "helix" ;;
      lazygit | 5) toggle_app "lazygit" ;;
      yazi | 6) toggle_app "yazi" ;;
      eza | 7) toggle_app "eza" ;;
      bat | 8) toggle_app "bat" ;;
      zoxide | 9) toggle_app "zoxide" ;;
      swap | 10) toggle_app "swap" ;;
      a | A)
        for app in "${!APP_SELECTIONS[@]}"; do
          APP_SELECTIONS[$app]=true
        done
        echo "  [✓] All apps selected"
        ;;
      n | N)
        for app in "${!APP_SELECTIONS[@]}"; do
          APP_SELECTIONS[$app]=false
        done
        echo "  [-] No apps selected"
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
  echo "📦 Installing selected applications..."
  echo ""

  for app in "${APPLICATIONS[@]}"; do
    if [[ "${APP_SELECTIONS[$app]}" == true ]]; then
      echo "========================================"
      echo "Installing $app..."
      echo "========================================"
      if [[ -f "$PACKAGES_DIR/$app.sh" ]]; then
        bash "$PACKAGES_DIR/$app.sh"
      else
        echo "⚠️  $app.sh not found, skipping..."
      fi
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
  clear_screen
  echo "============================================"
  echo "         LINUX SETUP UTILITY"
  echo "============================================"
  echo ""
  echo "  [1] Install Essential Packages"
  echo "  [2] Select & Install Applications"
  echo "  [3] Full Setup (Essentials + All Apps)"
  echo "  [4] Setup Config Symlinks"
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
        setup_essential
        echo ""
        echo "Press Enter to continue..."
        read -r
        ;;
      2)
        echo ""
        app_menu
        ;;
      3)
        echo ""
        setup_essential
        echo ""
        for app in "${APPLICATIONS[@]}"; do
          APP_SELECTIONS[$app]=true
        done
        install_selected
        ;;
      4)
        echo ""
        setup_symlinks
        echo ""
        echo "Press Enter to continue..."
        read -r
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
