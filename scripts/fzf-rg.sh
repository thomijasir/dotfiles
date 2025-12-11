#!/usr/bin/env bash

# # Live query from FZF
QUERY="${1:-""}"

# Parse %p folder
if [[ "$QUERY" == *"-p"* ]]; then
  SEARCH_PATH=$(echo "$QUERY" | sed -E 's/.*-p[[:space:]]+([^ ]+).*/\1/')
  SEARCH_PATTERN=$(echo "$QUERY" | sed -E 's/(.*)-p.*/\1/' | xargs)
else
  SEARCH_PATH="."
  SEARCH_PATTERN="$QUERY"
fi

RG_ARGS=(
  --line-number
  --column
  --no-heading
  --smart-case
)
# echo "Command  : rg ${RG_ARGS[@]} '${SEARCH_PATTERN}' '${SEARCH_PATH}'" >&2
rg ${RG_ARGS[@]} "$SEARCH_PATTERN" "$SEARCH_PATH" || true
