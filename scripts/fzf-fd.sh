#!/usr/bin/env bash

# Live query from FZF
QUERY="${1:-""}"

# Parse -p folder
if [[ "$QUERY" == *"-p"* ]]; then
  SEARCH_PATH=$(echo "$QUERY" | sed -E 's/.*-p[[:space:]]+([^ ]+).*/\1/')
  SEARCH_PATTERN=$(echo "$QUERY" | sed -E 's/(.*)-p.*/\1/' | xargs)
else
  SEARCH_PATH="."
  SEARCH_PATTERN="$QUERY"
fi

# FD options
# No colors to ensure safe parsing of filenames
FD_ARGS=(
  --hidden
  --follow
  --exclude .git
)

if [[ -z "$SEARCH_PATTERN" ]]; then
  fd "${FD_ARGS[@]}" . "$SEARCH_PATH" || true
else
  # Using full path search to match what fzf-rg does? 
  # Actually fzf-rg matches content. Here we match filenames.
  # If we want to filter by filename pattern:
  fd "${FD_ARGS[@]}" --full-path "$SEARCH_PATTERN" "$SEARCH_PATH" || true
fi