#!/usr/bin/env bash

# # Live query from FZF
# QUERY="$1"

# # Parse %p folder
# if [[ "$QUERY" == *"-p"* ]]; then
#   SEARCH_PATH=$(echo "$QUERY" | sed -E 's/.*%p[[:space:]]+([^ ]+).*/\1/')
#   SEARCH_PATTERN=$(echo "$QUERY" | sed -E 's/(.*)-p.*/\1/' | xargs)
# else
#   SEARCH_PATH="."
#   SEARCH_PATTERN="$QUERY"
# fi

# # Execute ripgrep
# rg --line-number --column --no-heading --smart-case "$SEARCH_PATTERN" "$SEARCH_PATH" || true


#!/usr/bin/env bash
# Usage:
#   hx-ripgrep.sh 'formatCurrency -p src/components -f *test.tsx'
#   hx-ripgrep.sh '-p src/components -f "*.spec.ts" formatCurrency'
#   hx-ripgrep.sh 'formatCurrency -f "*.{ts,tsx}"'

set -euo pipefail

QUERY="${1-}"  # whole query string from fzf

# Workspace root: prefer git top-level, else current directory (PWD)
WORKSPACE_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# --- portable absolute-path resolver (BSD/macOS friendly) ---
# Resolves a path either absolute or relative to WORKSPACE_ROOT; returns empty if not accessible.
abs_path() {
  local p="${1:-}"
  if [[ "${p}" = /* ]]; then
    if cd "${p}" 2>/dev/null; then pwd -P; else echo ""; fi
  else
    if cd "${WORKSPACE_ROOT}/${p}" 2>/dev/null; then pwd -P; else echo ""; fi
  fi
}

# Resolve physical workspace root
cd "${WORKSPACE_ROOT}" 2>/dev/null || { echo "Error: cannot cd to workspace root '${WORKSPACE_ROOT}'." >&2; exit 1; }
abs_root="$(pwd -P)"

SEARCH_PATTERN=""
SUBPATH=""                      # -p subdir inside workspace
declare -a FILE_GLOBS=()       # -f filename glob(s)  <-- initialized!

# --- tokenize query safely (respect quotes; no wildcard expansion) ---
set -f
# shellcheck disable=SC2086  # we intentionally use word-splitting on QUERY
set -- $QUERY
set +f

declare -a TOKENS=()
while [[ $# -gt 0 ]]; do
  case "${1-}" in
    -p)
      shift
      [[ $# -gt 0 ]] || { echo "Error: -p requires a value" >&2; exit 1; }
      SUBPATH="${1-}"; shift
      ;;
    -f)
      shift
      [[ $# -gt 0 ]] || { echo "Error: -f requires a value" >&2; exit 1; }
      FILE_GLOBS+=( "${1-}" ); shift
      ;;
    --)
      shift
      while [[ $# -gt 0 ]]; do TOKENS+=( "${1-}" ); shift; done
      ;;
    *)
      TOKENS+=( "${1-}" ); shift
      ;;
  esac
done

# Build text search pattern from remaining tokens (unless empty)
if [[ -n "${TOKENS[*]-}" ]]; then
  SEARCH_PATTERN="${TOKENS[*]}"
fi
if [[ -z "${SEARCH_PATTERN-}" ]]; then
  echo "No text pattern provided; refusing to search entire workspace." >&2
  exit 0
fi

# Normalize and validate -p subpath (optional)
RELATIVE_SUB_GLOB=""
if [[ -n "${SUBPATH-}" ]]; then
  abs_sub="$(abs_path "${SUBPATH}")"
  if [[ -z "${abs_sub-}" ]]; then
    echo "Warning: -p '${SUBPATH}' does not exist or is not accessible; ignoring." >&2
  else
    case "${abs_sub}" in
      "${abs_root}"/*)
        # derive relative path for glob: e.g. src/components/** to restrict area
        rel_sub="${abs_sub#${abs_root}/}"
        RELATIVE_SUB_GLOB="${rel_sub%/}/**"
        ;;
      *)
        echo "Warning: -p '${SUBPATH}' is outside workspace; ignoring." >&2
        ;;
    esac
  fi
fi

# Build ripgrep args: anchor to root; restrict via -g globs
RG_ARGS=(
  --line-number
  --column
  --no-heading
  --smart-case
)

# Include hidden **only when -p is used** (your requirement)
if [[ -n "${RELATIVE_SUB_GLOB-}" ]]; then
  RG_ARGS+=( --hidden )
fi

# Restrict search area to SUBPATH (if provided)
if [[ -n "${RELATIVE_SUB_GLOB-}" ]]; then
  RG_ARGS+=( -g "'${RELATIVE_SUB_GLOB}'" )
fi

# Apply filename globs from -f (each one is an inclusion)
# Example: -f '*test.tsx' -> -g '**/*test.tsx'
# Guard for empty arrays under set -u using default expansions.
if (( ${#FILE_GLOBS[@]:-0} > 0 )); then
  for fg in "${FILE_GLOBS[@]}"; do
    case "${fg}" in
      **/*) RG_ARGS+=( -g "${fg}" ) ;;
      */*)  RG_ARGS+=( -g "${fg}" ) ;;
      *)    RG_ARGS+=( -g "**/${fg}" ) ;;
    esac
  done
fi

# Debug (stderr) — guard array expansion for set -u
# echo "Workspace: ${abs_root}" >&2
# echo "Pattern  : ${SEARCH_PATTERN}" >&2
# echo "Subpath  : ${SUBPATH:-<none>} (glob: ${RELATIVE_SUB_GLOB:-<none>})" >&2
# if (( ${#FILE_GLOBS[@]:-0} > 0 )); then
#   printf "FileGlobs: %s\n" "${FILE_GLOBS[*]}" >&2
# fi
# echo "Command  : rg ${RG_ARGS[@]} -- '${SEARCH_PATTERN}' '${abs_root}'" >&2
# Return Correct Function
rg "${RG_ARGS[@]}" -- "$SEARCH_PATTERN" "$abs_root" || true

