#!/bin/bash

# Harpoon-like Bookmark Script
# Author: Thomi Jasir (thomijasir@gmail.com)

command_prompt="$1"
file_path="$2"
cursor_line="$3"
store_file="$HOME/.harpoon.json"

# Get current working directory as the project key
get_project_key() {
  pwd | sed 's/\//\\\//g'
}

# Initialize empty harpoon file if doesn't exist
init_harpoon_file() {
  if [ ! -f "$store_file" ]; then
    echo '{}' >"$store_file"
  fi
}

# Helper to add or move a bookmark to the front of the list
upsert_bookmark() {
  local p_key="$1"
  local f_path="$2"
  local temp_json=$(mktemp)

  jq --arg key "$p_key" --arg path "$f_path" '
        if has($key) then
            .[$key] = ([$path] + (.[$key] | map(select(. != $path))))
        else
            .[$key] = [$path]
        end
    ' "$store_file" >"$temp_json" && mv "$temp_json" "$store_file"
}

# Add file to bookmarks
add_bookmark() {
  init_harpoon_file

  if [ -z "$file_path" ]; then
    echo "Error: No file path provided"
    exit 1
  fi

  # Get absolute path
  abs_path=$(realpath "$file_path" 2>/dev/null || echo "$file_path")
  project_key=$(get_project_key)

  upsert_bookmark "$project_key" "$abs_path"

  echo "✓ Bookmarked: $abs_path"
}

# List bookmarks with fzf
list_bookmarks() {
  init_harpoon_file

  project_key=$(get_project_key)

  # Check if project has bookmarks
  has_bookmarks=$(jq -r --arg key "$project_key" 'has($key)' "$store_file")

  if [ "$has_bookmarks" != "true" ]; then
    echo "No bookmarks found for this project"
    exit 0
  fi

  # Get bookmarks and format them
  jq -r --arg key "$project_key" '.[$key][]' "$store_file" | while read -r filepath; do
    if [ -f "$filepath" ]; then
      # Show parent folder + filename
      parent=$(basename "$(dirname "$filepath")")
      filename=$(basename "$filepath")
      echo "$parent/$filename|$filepath"
    fi
  done
}

# Open bookmark with fzf selection
open_bookmark() {
  init_harpoon_file

  project_key=$(get_project_key)
  has_bookmarks=$(jq -r --arg key "$project_key" 'has($key)' "$store_file")

  if [ "$has_bookmarks" != "true" ]; then
    echo "No bookmarks found for this project"
    exit 0
  fi

  # Create temp file for fzf input
  temp_file=$(mktemp)

  jq -r --arg key "$project_key" '.[$key][]' "$store_file" | while read -r filepath; do
    if [ -f "$filepath" ]; then
      parent=$(basename "$(dirname "$filepath")")
      filename=$(basename "$filepath")
      echo "$parent/$filename|$filepath"
    fi
  done >"$temp_file"

  # Check if temp file is empty
  if [ ! -s "$temp_file" ]; then
    echo "No valid bookmarks found"
    rm "$temp_file"
    exit 0
  fi

  # Use fzf to select
  selected=$(cat "$temp_file" | fzf -m --delimiter='|' --with-nth=1 --preview='bat --color=always {2} 2>/dev/null || cat {2}' --reverse --preview-window=right:60%)
  rm "$temp_file"

  if [ -n "$selected" ]; then
    # Read selected paths into an array to handle spaces correctly
    paths=()
    while IFS= read -r line; do
      paths+=("$line")
    done < <(echo "$selected" | cut -d'|' -f2)

    # Update MRU: move opened files to the front
    for path in "${paths[@]}"; do
      upsert_bookmark "$project_key" "$path"
    done

    if command -v hx-open.sh &>/dev/null; then
      hx-open.sh "${paths[@]}"
    elif [ -n "$EDITOR" ]; then
      $EDITOR "${paths[0]}"
    else
      hx "${paths[0]}"
    fi
  fi
}

# Remove bookmark
remove_bookmark() {
  init_harpoon_file

  project_key=$(get_project_key)
  has_bookmarks=$(jq -r --arg key "$project_key" 'has($key)' "$store_file")

  if [ "$has_bookmarks" != "true" ]; then
    echo "No bookmarks found for this project"
    exit 0
  fi

  # Create temp file for fzf input
  temp_file=$(mktemp)

  jq -r --arg key "$project_key" '.[$key][]' "$store_file" | while read -r filepath; do
    if [ -f "$filepath" ]; then
      parent=$(basename "$(dirname "$filepath")")
      filename=$(basename "$filepath")
      echo "$parent/$filename|$filepath"
    fi
  done >"$temp_file"

  selected=$(cat "$temp_file" | fzf --delimiter='|' --with-nth=1 --prompt="Remove bookmark: ")
  rm "$temp_file"

  if [ -n "$selected" ]; then
    selected_path=$(echo "$selected" | cut -d'|' -f2)

    temp_json=$(mktemp)
    jq --arg key "$project_key" --arg path "$selected_path" '
            .[$key] = (.[$key] | map(select(. != $path)))
        ' "$store_file" >"$temp_json" && mv "$temp_json" "$store_file"

    echo "✓ Removed bookmark: $selected_path"
  fi
}

# Main command handler
case $command_prompt in
  "add")
    add_bookmark
    ;;
  "list")
    list_bookmarks
    ;;
  "open")
    open_bookmark
    ;;
  "remove" | "rm")
    remove_bookmark
    ;;
  *)
    echo "Usage: $0 {add|list|open|remove} [file_path]"
    echo ""
    echo "Commands:"
    echo "  add [file]    - Add file to bookmarks"
    echo "  list          - List all bookmarks"
    echo "  open          - Open bookmark with fzf"
    echo "  remove        - Remove bookmark with fzf"
    exit 1
    ;;
esac
