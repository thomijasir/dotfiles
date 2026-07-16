#!/usr/bin/env bash
set -euo pipefail

# Check if curl is installed
if ! command -v curl &> /dev/null; then
    echo "❌ curl could not be found. Please install curl and try again."
    exit 1
fi

# Available AI coding CLI tools
declare -a TOOLS=(
    "Claude Code|https://claude.ai/install.sh|bash"
    "Codex CLI|https://chatgpt.com/codex/install.sh|sh"
    "OpenCode|https://opencode.ai/install|bash"
)

echo "🤖 AI Coding CLI Installer"
echo "Select a tool to install:"
echo
for i in "${!TOOLS[@]}"; do
    IFS='|' read -r name url shell <<< "${TOOLS[$i]}"
    echo "  $((i + 1))) $name"
done
echo "  0) Exit"
echo

read -rp "Enter choice [0-${#TOOLS[@]}]: " choice

if [[ ! "$choice" =~ ^[0-9]+$ ]] || (( choice < 0 || choice > ${#TOOLS[@]} )); then
    echo "❌ Invalid choice."
    exit 1
fi

if (( choice == 0 )); then
    echo "👋 Exiting."
    exit 0
fi

IFS='|' read -r name url shell <<< "${TOOLS[$((choice - 1))]}"

echo "📦 Installing $name..."
curl -fsSL "$url" | "$shell"
echo "✅ $name installation complete!"
