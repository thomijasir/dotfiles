#!/usr/bin/env bash
set -euo pipefail

# 1. Define the NVM version (Check https://github.com/nvm-sh/nvm for the latest version)
NVM_VERSION="v0.40.5"

echo "📦 Installing node version manager.."

# 2. Ensure dependencies are installed
if ! command -v curl &> /dev/null; then
    echo "curl not found. Installing curl..."
    sudo apt-get update && sudo apt-get install -y curl || sudo yum install -y curl || sudo dnf install -y curl
fi

# 3. Download and run the official NVM install script
echo "Downloading and installing NVM version $NVM_VERSION..."
curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh" | bash

# 4. Load NVM into the current script session
# NVM is a shell function, not a binary, so it must be sourced.
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# 5. Verify installation
if command -v nvm &> /dev/null; then
    echo "----------------------------------------"
    echo "✅ NVM installed successfully!"
    echo "NVM Version: $(nvm --version)"
    echo "----------------------------------------"
    echo ""
    echo "To install the latest Node.js version, run:"
    echo "  nvm install node"
    echo ""
    echo "To install a specific Node.js version, run:"
    echo "  nvm install 18"
else
    echo "❌ NVM installation failed."
    echo "Please try restarting your terminal and running 'nvm --version' manually."
    exit 1
fi