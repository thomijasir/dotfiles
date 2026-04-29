#!/usr/bin/env bash
set -euo pipefail

echo "📦 Installing docker CE Server..."

SUDO=()
TARGET_USER="${SUDO_USER:-${USER:-}}"

if [[ "$EUID" -ne 0 ]]; then
  if ! command -v sudo >/dev/null 2>&1; then
    echo "❌ Docker installation requires root privileges."
    echo "Run setup.py as your normal login user, but make sure that user has sudo access."
    exit 1
  fi

  if ! sudo -n true 2>/dev/null && ! sudo -v; then
    echo "❌ Current user does not have working sudo access."
    echo "Add this login user to the sudo group first, then run setup.py again without sudo."
    exit 1
  fi

  SUDO=(sudo)
fi

if command -v docker &>/dev/null; then
  echo "docker is already installed"
else
  installer="$(mktemp)"
  trap 'rm -f "$installer"' EXIT

  curl -fsSL https://get.docker.com -o "$installer"
  "${SUDO[@]}" sh "$installer"
fi

if [ "$(ps -p 1 -o comm=)" = "systemd" ]; then
  "${SUDO[@]}" systemctl enable --now docker
else
  echo "ℹ️  systemd is not running; skipping Docker service start."
fi

if [[ -n "$TARGET_USER" ]] && id "$TARGET_USER" >/dev/null 2>&1; then
  "${SUDO[@]}" usermod -aG docker "$TARGET_USER"
  echo "✅ Added $TARGET_USER to docker group."
  echo "ℹ️  Log out and back in before running docker without sudo."
fi

echo "Create default network.."
if "${SUDO[@]}" docker info >/dev/null 2>&1; then
  if ! "${SUDO[@]}" docker network inspect web_network >/dev/null 2>&1; then
    "${SUDO[@]}" docker network create web_network
  else
    echo "web_network already exists"
  fi
else
  echo "ℹ️  Docker daemon is not running; skipping web_network creation."
fi

echo "✅ Docker setup complete!"
