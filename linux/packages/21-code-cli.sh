#!/usr/bin/env bash
set -euo pipefail

# Available AI coding CLI tools
declare -a TOOLS=(
    "Claude Code|https://claude.ai/install.sh|bash"
    "Codex CLI|https://chatgpt.com/codex/install.sh|sh"
    "OpenCode|https://opencode.ai/install|bash"
    "CommandCode|command-code@latest|npm"
    "Google GeminiCLI|@google/gemini-cli|npm"
    "X AI CLI|https://x.ai/cli/install.sh|bash"
    "KimiCode|https://code.kimi.com/kimi-code/install.sh|bash"
)

echo "🤖 AI Coding CLI Installer"
echo "Select a tool to install:"
echo
for i in "${!TOOLS[@]}"; do
    IFS='|' read -r name source installer <<< "${TOOLS[$i]}"
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

IFS='|' read -r name source installer <<< "${TOOLS[$((choice - 1))]}"

echo "📦 Installing $name..."

case "$installer" in
    npm)
        if ! command -v npm &> /dev/null; then
            echo "❌ npm could not be found. Please install Node.js and npm, then try again."
            exit 1
        fi
        npm install --global "$source"
        ;;
    bash|sh)
        if ! command -v curl &> /dev/null; then
            echo "❌ curl could not be found. Please install curl and try again."
            exit 1
        fi
        curl -fsSL "$source" | "$installer"
        ;;
    *)
        echo "❌ Unsupported installer type: $installer"
        exit 1
        ;;
esac

echo "✅ $name installation complete!"
