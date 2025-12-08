#!/usr/bin/env bash

# Live query from FZF
QUERY="$1"

# Parse %p folder
if [[ "$QUERY" == *"%p"* ]]; then
  SEARCH_PATH=$(echo "$QUERY" | sed -E 's/.*%p[[:space:]]+([^ ]+).*/\1/')
  SEARCH_PATTERN=$(echo "$QUERY" | sed -E 's/(.*)%p.*/\1/' | xargs)
else
  SEARCH_PATH="."
  SEARCH_PATTERN="$QUERY"
fi

# Execute ripgrep
rg --line-number --column --no-heading --smart-case "$SEARCH_PATTERN" "$SEARCH_PATH" || true

# #!/usr/bin/env bash

# Combine all arguments into one query string
# query="$*"

# # Check for %p separator
# if [[ "$query" == *"%p"* ]]; then
#   search_term="${query%%%p*}"
#   path_term="./${query##*%p}"
# else
#   search_term="$query"
#   path_term="."
# fi

# # Trim whitespace
# search_term=$(echo "$search_term" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
# path_term=$(echo "$path_term" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

# # Default search term to . if empty (matches original behavior of showing all non-empty lines)
# if [ -z "$search_term" ]; then
#   search_term="."
# fi

# # Default path to . if empty
# if [ -z "$path_term" ]; then
#   path_term="."
# fi

# # Run rg
# # We use || true to prevent errors from crashing the pipe or showing ugly output
# # We use -- to separate options from pattern, allowing patterns starting with -
# rg --line-number --column --no-heading --smart-case -- "$search_term" $path_term 2>/dev/null || true
