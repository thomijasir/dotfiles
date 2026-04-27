#!/usr/bin/env bash
set -euo pipefail

echo "📦 Installing docker CE Server..."

if command -v docker &>/dev/null; then
  echo "docker is already installed"
else
  curl -fsSL https://get.docker.com -o get-docker.sh
  sudo sh get-docker.sh && rm -rf get-docker.sh
  echo "Create default network.."
  docker network create web_network
fi
