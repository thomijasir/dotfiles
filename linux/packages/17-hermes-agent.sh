#!/usr/bin/env bash
set -euo pipefail

# Check if curl is installed
if ! command -v curl &> /dev/null; then
    echo "❌ curl could not be found. Please install curl and try again."
    exit 1
fi

echo "📦 Installing hermes agent.."
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash

echo "✅ Hermes agent installation complete!"