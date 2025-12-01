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

  # Check if project key exists in JSON
  has_project=$(jq -r --arg key "$project_key" 'has($key)' "$store_file")

  if [ "$has_project" = "true" ]; then
    # Remove file if it exists (to move it to the end)
    jq --arg key "$project_key" --arg path "$abs_path" '
            .[$key] = (.[$key] | map(select(. != $path)))
        ' "$store_file" >"$store_file.tmp" && mv "$store_file.tmp" "$store_file"

    # Add file to the end
    jq --arg key "$project_key" --arg path "$abs_path" '
            .[$key] += [$path]
        ' "$store_file" >"$store_file.tmp" && mv "$store_file.tmp" "$store_file"
  else
    # Create new project key with file
    jq --arg key "$project_key" --arg path "$abs_path" '
            .[$key] = [$path]
        ' "$store_file" >"$store_file.tmp" && mv "$store_file.tmp" "$store_file"
  fi

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
  selected=$(cat "$temp_file" | fzf -m --delimiter='|' --with-nth=1 --preview='bat --color=always {2} 2>/dev/null || cat {2}' --preview-window=right:60%)
  rm "$temp_file"

  if [ -n "$selected" ]; then
    selected_path=$(echo "$selected" | cut -d'|' -f2)

    # Check if hx-yazi.sh exists, otherwise use default editor
    if command -v hx-yazi.sh &>/dev/null; then
      # open to top pane
      pane_id=$(wezterm cli get-pane-direction up)
      printf ":o '%s'\r" "$selected_path" | wezterm cli send-text --pane-id "$pane_id" --no-paste
      wezterm cli activate-pane-direction --pane-id $pane_id up
    elif [ -n "$EDITOR" ]; then
      $EDITOR "$selected_path"
    else
      hx "$selected_path"
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

    jq --arg key "$project_key" --arg path "$selected_path" '
            .[$key] = (.[$key] | map(select(. != $path)))
        ' "$store_file" >"$store_file.tmp" && mv "$store_file.tmp" "$store_file"

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

# #!/bin/sh

# # Original Scripts
# # Author Thomi Jasir (thomijasir@gmail.com)

# # set -x

# # command_prompt="$1"
# # file_path="$2"
# # cursor_line="$3"
# # hx_pane_id=$(echo $WEZTERM_PANE)
# # pwd=$(PWD)
# # basedir=$(dirname "$filename")
# # basename=$(basename "$filename")
# # basename_without_extension="${basename%.*}"
# # extension="${filename##*.}"
# # store_file=".harpoon.json"

# # json management using jq
# # format json for harppon file
# # {
# #   "your_base_dir": ["your_path_file"],
# #   "other_workspace": ["src/component/index.tsx"]
# # }
# # json file will put in the home dir {$HOME}

# case $command_prompt in
#   "add")
#     # TODO: add buffer filepath to list
#     # echo "is works"
#     # check is has .harpoon.json file in the root project
#     # if dont have create file .harpoon.json
#     # if user want to add path file check the exsisitng path file
#     # if path available then replace previous one and move to latest order file on the end of file
#     # everytime insert or replace always append make sure latest add is on below
#     ;;
#   "list")
#     # TODO: open fzf and see list file that saved
#     # check is has .harpoon.json file
#     # if dont have you just saying you dont have bookmark list
#     # if has then open fzf with format filname and 1st parent folder
#     # example /src/component/card/propertyList.tsx then you should show on fzf card/propertyList.tsx
#     ;;
#   "open")
#     # TODO: fzf slect and open to top
#     # check is has .harpoon.json file in the root project
#     # if dont have just echo "you dont have bookmark list"
#     # execute command hx-yazi.sh following the path that we select on fzf example hx-yazi.sh {file_path} i have added to alias a
#     hx-yazi.sh $file_path
#     ;;
# esac
