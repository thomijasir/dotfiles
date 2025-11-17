#!/usr/bin/env bash
# hx-snippet.sh — Echo code snippets by key
# Usage:
#   ./hx-snippet.sh rct      # React functional component (TSX)
#   ./hx-snippet.sh clg      # console.log() snippet
#   ./hx-snippet.sh help     # show help
#
# You can also pipe to a file:
#   ./hx-snippet.sh rct > Component.tsx

set -euo pipefail

show_help() {
  cat <<'HELP'
Usage:
  hx-snippet.sh <key>

Available keys:
  rct   React functional component (TypeScript/TSX)
  clg   console.log() snippet
  help  Show this help message

Examples:
  ./hx-snippet.sh rct > Component.tsx
  ./hx-snippet.sh clg >> index.ts
HELP
}

if [[ $# -lt 1 ]]; then
  show_help
  exit 1
fi

key="$1"

case "$key" in
  rct)
    cat <<'EOF'
import React from "react";

export const Component: React.FC = () => {
  return (
    <div>
      <p>hello component</p>
    </div>
  );
};
EOF
    ;;
  clg)
    echo "console.log("
    ;;
  help)
    show_help
    ;;
  *)
    echo "Unknown option: $key"
    echo "Use 'help' to see available options."
    exit 1
    ;;
esac
