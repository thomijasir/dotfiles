#!/usr/bin/env bash
set -euo pipefail

# Check if curl is installed
if ! command -v curl &> /dev/null; then
    echo "❌ curl could not be found. Please install curl and try again."
    exit 1
fi

echo "📦 Installing tailscale internet.."
curl -fsSL https://tailscale.com/install.sh | sh

echo "✅ tailscale internet installation complete!"