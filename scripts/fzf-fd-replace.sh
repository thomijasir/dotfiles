#!/usr/bin/env bash

set -euo pipefail

# --- Prerequisites ------------------------------------------------------------
need() {
  if ! command -v "$1" &>/dev/null; then
    echo "Missing dependency: $1" >&2
    exit 1
  fi
}

need fd
need fzf
need sed
need awk
need mv
need mkdir
need dirname
need basename

# Detect OS for sed usage
OS="$(uname -s)"
# MacOS sed handles -E, but inplace is different. We are not using inplace for file renaming (mv).
# We only use sed for string manipulation here.

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
  fzf-fd.sh | fzf --disabled --reverse --print-query --multi \
    --prompt='Rename> ' \
    --bind="change:reload:fzf-fd.sh {q}" \
    --preview "bat --style=numbers --color=always {} 2>/dev/null || ls -F --color=always {}" \
    --preview-window "right,60%,~3" \
    --bind 'ctrl-a:toggle-all' \
    --header $'Ctrl-A: Toggle all | Enter: Confirm | Esc: Cancel\nAutomatic and smart file folder replace tool'
}

perform_replacement_cycle() {
  # 1. Search and Select
  local result
  result=$(select_matches)

  # Check if cancelled
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
    echo "Could not determine search pattern from query."
    return 1
  fi

  # 3. Summary & Replacement Input
  local match_count
  match_count=$(echo "$selections" | wc -l | xargs)

  echo
  echo -e "🔍 Pattern: \033[1;34m$search_pattern\033[0m"
  echo -e "📋 Selected: \033[1;33m$match_count\033[0m items."
  echo

  local replacement
  read -e -r -p "Rename match to: " replacement

  # 4. Dry Run Preview
  echo
  echo -e "\033[1;36m🔍 Dry-run preview (Deepest items first):\033[0m"

  local sed_pat
  sed_pat=$(escape_pattern "$search_pattern")
  local sed_rep
  sed_rep=$(escape_replacement "$replacement")

  # Sort selections by length of path (descending) to simulate deepest-first processing
  local sorted_selections
  sorted_selections=$(echo "$selections" | awk '{ print length, $0 }' | sort -nr | cut -d" " -f2-)

  local preview_count=0
  local preview_limit=20
  local files_to_rename=()
  local target_names=()

  # We read into arrays to store the plan
  while IFS= read -r item; do
    if [[ -z "$item" ]]; then continue; fi

    local dir
    dir=$(dirname "$item")
    local base
    base=$(basename "$item")

    # Apply replacement ONLY to the basename
    # This prevents renaming the parent directory path in the middle of processing a child
    # (The parent directory should be selected separately if it needs renaming)
    local new_base
    new_base=$(echo "$base" | sed -E "s/${sed_pat}/${sed_rep}/g")

    if [[ "$base" != "$new_base" ]]; then
      local new_path="$dir/$new_base"

      files_to_rename+=("$item")
      target_names+=("$new_path")

      if [[ $preview_count -lt $preview_limit ]]; then
        echo -e "\033[0;35m$item\033[0m"
        echo -e "  \033[0;31m- $base\033[0m"
        echo -e "  \033[0;32m+ $new_base\033[0m"
        ((preview_count++))
      fi
    fi
  done <<<"$sorted_selections"

  local change_count=${#files_to_rename[@]}

  if [[ $change_count -eq 0 ]]; then
    echo "No filenames changed based on pattern '$search_pattern'."
    return 1
  fi

  if [[ $preview_count -ge $preview_limit ]]; then
    local remaining=$((change_count - preview_count))
    if [[ $remaining -gt 0 ]]; then
      echo "... and $remaining more items."
    fi
  fi

  # 5. Confirmation
  echo
  local confirm
  read -r -p "Apply $change_count renames? [y/N]: " confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    return 0
  fi

  # 6. Apply Changes
  echo "Applying changes..."

  for ((i = 0; i < change_count; i++)); do
    local old="${files_to_rename[$i]}"
    local new="${target_names[$i]}"

    # Check if old exists (it might have been moved if we messed up order, but deepest-first prevents this for parents)
    if [[ -e "$old" ]]; then
      # Ensure parent dir exists (it should, unless we moved it?
      # If we moved parent `src/test` -> `src/spec` BEFORE `src/test/file`, then `src/test/file` is gone.
      # But we sorted by length desc, so `src/test/file` (len 13) comes before `src/test` (len 8).
      # So we move `src/test/file` -> `src/test/newfile`.
      # THEN we move `src/test` -> `src/newtest`.
      # This works correctly.

      mv -n "$old" "$new"
      echo "Moved: $old -> $new"
    else
      echo "Skipped (not found): $old"
    fi
  done

  echo "✅ Rename complete."
  return 0
}

# --- Main ---------------------------------------------------------------------

while true; do
  if ! perform_replacement_cycle; then
    :
  fi

  echo
  read -r -p "Confirm exit? [y/N]: " choice
  if [[ ! "$choice" =~ ^[Yy]$ ]]; then
    echo "Bye."
    break
  fi
done
