#!/usr/bin/env bash

set -euo pipefail

# --- Prerequisites ------------------------------------------------------------
need() {
  if ! command -v "$1" &>/dev/null; then
    echo "Missing dependency: $1" >&2
    exit 1
  fi
}

need rg
need fzf
need sed

# Detect OS for sed usage
OS="$(uname -s)"
SED_INPLACE=("-i")
if [[ "$OS" == "Darwin" ]]; then
  SED_INPLACE=("-i" "")
fi

# --- Helper Functions ---------------------------------------------------------

# Escape replacement string for sed (escape \ / &)
escape_replacement() {
  printf '%s' "$1" | sed -e 's/[\\/&]/\\&/g'
}

# Escape regex pattern for sed (escape all special chars and delimiter /)
escape_pattern() {
  printf '%s' "$1" | sed -e 's/[][\/.^$*+?(){}|]/\\&/g'
}

# --- Core Logic ---------------------------------------------------------------

select_matches() {
  # Run fzf with preview and reload capability
  # --print-query: Print the query as the first line of output
  fzf-rg.sh | fzf --disabled --reverse --print-query --multi \
    --prompt='Replace> ' \
    --delimiter ':' \
    --bind="change:reload:fzf-rg.sh {q}" \
    --preview "fzf-bat.sh {2} {1}" \
    --preview-window "right,60%,+{2}+3/3,~3" \
    --bind 'ctrl-a:toggle-all' \
    --header $'Ctrl-A: Toggle all | Enter: Confirm | Esc: Cancel\nAutomatic and smart string replacement tool'
}

perform_replacement_cycle() {
  # 1. Search and Select
  local result
  result=$(select_matches)

  # Check if cancelled (fzf returns empty if no selection made usually, but with print-query it returns query at least?)
  # If user cancels fzf (ESC), output is empty or exit code is non-zero.
  # We captured output.
  if [[ -z "$result" ]]; then
    return 1
  fi

  # Parse Output
  local query
  query=$(head -n1 <<<"$result")
  local selections
  selections=$(tail -n +2 <<<"$result")

  if [[ -z "$selections" ]]; then
    echo "No items selected."
    return 1
  fi

  # 2. Extract Pattern
  # Extract search pattern from query (handle 'pattern -p path' format)
  local search_pattern
  search_pattern=$(echo "$query" | sed -E 's/(.*)-p.*/\1/' | xargs)

  if [[ -z "$search_pattern" ]]; then
    echo "Could not determine search pattern."
    return 1
  fi

  # 3. Summary & Replacement Input
  local file_count
  file_count=$(echo "$selections" | cut -d: -f1 | sort -u | wc -l | xargs)
  local match_count
  match_count=$(echo "$selections" | wc -l | xargs)

  echo
  echo -e "🔍 Pattern: \033[1;34m$search_pattern\033[0m"
  echo -e "📋 Selected: \033[1;33m$match_count\033[0m matches in \033[1;33m$file_count\033[0m files."
  echo

  local replacement
  read -e -r -p "Replace with: " replacement

  # 4. Dry Run Preview
  echo
  echo -e "\033[1;36m🔍 Dry-run preview:\033[0m"

  local sed_pat
  sed_pat=$(escape_pattern "$search_pattern")
  local sed_rep
  sed_rep=$(escape_replacement "$replacement")

  # Limit preview to first 10 matches to avoid spamming if many selected
  local counter=0
  local preview_limit=10

  # Iterate for preview
  while IFS= read -r line_item; do
    ((counter++))
    local file line_num
    file=$(echo "$line_item" | cut -d: -f1)
    line_num=$(echo "$line_item" | cut -d: -f2)

    if [[ -f "$file" ]]; then
      local original
      original=$(sed -n "${line_num}p" "$file")
      local modified
      modified=$(echo "$original" | sed -E "s/${sed_pat}/${sed_rep}/g")

      echo -e "\033[0;35m$file:$line_num\033[0m"
      echo -e "  \033[0;31m- $original\033[0m"
      echo -e "  \033[0;32m+ $modified\033[0m"
    fi

    if [[ $counter -ge $preview_limit ]]; then
      local remaining=$((match_count - counter))
      if [[ $remaining -gt 0 ]]; then
        echo "... and $remaining more matches."
      fi
      break
    fi
  done <<<"$selections"

  # 5. Confirmation
  echo
  local confirm
  read -r -p "Apply changes? [y/N]: " confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    return 0
  fi

  # 6. Apply Changes
  echo "Applying changes..."

  # Create temp file for sorting selections
  local temp_list
  temp_list=$(mktemp)

  # Sort selections by file then line number (numeric).
  # Use -u to avoid duplicate sed commands for multiple matches on the same line.
  echo "$selections" | cut -d: -f1,2 | sort -u -t: -k1,1 -k2,2n >"$temp_list"

  local current_file=""
  local sed_cmds=()

  # Function to execute accumulated sed commands for a file
  process_batch() {
    if [[ -z "$current_file" || ${#sed_cmds[@]} -eq 0 ]]; then return; fi

    # Build sed arguments: -i '' -E -e '...' -e '...'
    local args=("${SED_INPLACE[@]}" -E)
    for cmd in "${sed_cmds[@]}"; do
      args+=("-e" "$cmd")
    done

    sed "${args[@]}" "$current_file"
    echo "Modified $current_file"
  }

  while IFS=: read -r f l; do
    if [[ "$f" != "$current_file" ]]; then
      process_batch
      current_file="$f"
      sed_cmds=()
    fi
    # Add replacement command for specific line
    sed_cmds+=("${l}s/${sed_pat}/${sed_rep}/g")
  done <"$temp_list"

  # Process last file
  process_batch

  rm -f "$temp_list"
  echo "✅ Replacement complete."
  return 0
}

# --- Main ---------------------------------------------------------------------

while true; do
  if ! perform_replacement_cycle; then
    # If function returns 1 (error/cancel early), we assume user might want to stop or retry
    # But usually perform_replacement_cycle prints its own status.
    :
  fi

  echo
  read -r -p "Confirm exit? [y/N]: " choice
  if [[ ! "$choice" =~ ^[Yy]$ ]]; then
    echo "Bye."
    break
  fi
done
