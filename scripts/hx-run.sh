#!/usr/bin/env bash
# Auto-detect project type and run it in a bottom WezTerm pane (default 20%).
# - Node (package.json) -> npm run start
# - Rust (Cargo.toml)   -> cargo run
#
# Usage:
#   ./runproj.sh              # detect in current dir
#   ./runproj.sh /path/to/app # optional target dir
#
# Options via env:
#   PERCENT=25 ./runproj.sh   # bottom pane height percent (default 20)

set -euo pipefail

# ---------- config ----------
PERCENT="${PERCENT:-20}"

# ---------- helpers ----------
die() {
  echo "❌ $*" >&2
  exit 1
}

is_cmd() { command -v "$1" >/dev/null 2>&1; }

is_node() { [[ -f package.json ]]; }
is_rust() { [[ -f Cargo.toml ]]; }

wezterm_split_bottom() {
  # Runs provided command in a bottom 20% pane, creating WezTerm GUI if needed.
  local run_cmd="$1"

  if ! is_cmd wezterm; then
    echo "⚠️  wezterm not found; running in current shell instead."
    # Keep the shell open after the command in interactive usage
    bash -lc "$run_cmd"
    return
  fi

  # If GUI isn’t up yet, start one in this cwd and wait briefly.
  if ! wezterm cli list >/dev/null 2>&1; then
    # Launch a GUI window anchored to current dir; background it.
    wezterm start --cwd "$PWD" -- bash -lc "exec \$SHELL -l" >/dev/null 2>&1 &
    # Wait (max ~5s) for the GUI/daemon to be ready.
    for _ in {1..50}; do
      if wezterm cli list >/dev/null 2>&1; then
        break
      fi
      sleep 0.1
    done
  fi

  # Split the active pane at the bottom with given percent and run the command.
  # We use bash -lc so your shell init runs; `exec $SHELL -l` keeps the pane open.
  wezterm cli split-pane \
    --bottom \
    --percent "$PERCENT" \
    --cwd "$PWD" \
    -- bash -lc "$run_cmd; echo; echo '--- finished: $run_cmd ---'; exec \$SHELL -l"
}

main() {
  local target_dir="${1:-.}"
  [[ -d "$target_dir" ]] || die "Directory not found: $target_dir"
  cd "$target_dir"

  if is_node; then
    echo "🔎 Detected Node project (package.json)."
    wezterm_split_bottom "npm run start"
  elif is_rust; then
    echo "🔎 Detected Rust project (Cargo.toml)."
    wezterm_split_bottom "cargo run"
  else
    die "No known project detected.\nLooked for: package.json (Node) or Cargo.toml (Rust)."
  fi
}

main "$@"
