#!/usr/bin/env bash
set -euo pipefail

echo "Installing OpenSSH server..."
sudo apt install -y openssh-server

echo "Enabling and starting the SSH service..."
sudo systemctl enable --now ssh

echo "OpenSSH server is installed and the SSH service is enabled and started."
