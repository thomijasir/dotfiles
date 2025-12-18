#!/usr/bin/env bash

# Original Scripts
# Author Thomi Jasir (thomijasir@gmail.com)

# Exit on error, undefined var, or pipe fail (optional, but good for robustness)
# set -e

# Turn off debug mode for production use
# set -x

command_prompt="$1"
file_path="$2"
cursor_line="$3"

# Define missing variables
filename="$file_path"
hx_pane_id="${WEZTERM_PANE}"
current_dir="$PWD"
basedir=$(dirname "$file_path")
basename=$(basename "$file_path")
# Safe way to get extension in bash
extension="${filename##*.}"
basename_without_extension="${basename%.*}"

# Helper for sending text to a pane
send_to_pane() {
  local pane_id="$1"
  local text="$2"
  echo "$text" | wezterm cli send-text --pane-id "$pane_id" --no-paste
}

# Helper to activate a pane
activate_pane() {
  local direction="$1"
  local pane_id="$2"
  if [ -n "$pane_id" ]; then
    wezterm cli activate-pane-direction --pane-id "$pane_id" "$direction"
  else
    wezterm cli activate-pane-direction "$direction"
  fi
}

split_pane_down() {
  # Check if a pane exists down
  bottom_pane_id=$(wezterm cli get-pane-direction down)
  if [ -z "${bottom_pane_id}" ]; then
    # Open zsh if no pane exists
    bottom_pane_id=$(wezterm cli split-pane -- zsh -f)
  fi

  activate_pane "down" "$bottom_pane_id"
  # Check if running lazygit to quit it before sending new commands
  program=$(wezterm cli list | awk -v pane_id="$bottom_pane_id" '$3==pane_id { print $6 }')
  if [ "$program" = "lazygit" ]; then
    send_to_pane "$bottom_pane_id" "q"
  fi
  # Return the pane ID for further use
  echo "$bottom_pane_id"
}

split_pane_run() {
  local direction="$1" # --bottom or --right
  local percent="$2"
  local cmd="$3"
  # Use zsh interactive login shell to ensure environment is loaded
  wezterm cli split-pane "$direction" --percent "$percent" --cwd "$current_dir" -- zsh -i -c -lc "$cmd"
}

case "$command_prompt" in
  "ai_gemini")
    split_pane_run "--right" "40" "gemini; exit"
    ;;
  "ai_claude")
    split_pane_run "--right" "40" "claude; exit"
    ;;
  "blame")
    split_pane_run "--bottom" "50" "tig blame $file_path +$cursor_line; exit"
    ;;
  "git_blame")
    # Base Command
    # git blame -L $cursor_line,+1 $file_path
    git blame -L $cursor_line,+1 $file_path | awk '{
        icon = ($1 ~ /^0+$/) ? "✎" : "";
        sub(/\).*/, ")");
        print icon, $0;
      }'
    ;;
  "copy_filename")
    basename '%{buffer_name}' | pbcopy
    echo '✅ Filename copied!'
    ;;
  "copy_abs_path")
    echo -n '%{buffer_name}' | pbcopy
    echo '✅ Absolute path copied!'
    ;;
  "yazi")
    # Complex command needs proper quoting
    run_cmd='tmp="$(mktemp -t yazi-chooser.XXXXXX)"; yazi "$PWD" --chooser-file="$tmp"; [ -s "$tmp" ] && hx-open.sh "$(head -n1 "$tmp")"; rm -rf "$tmp"'
    split_pane_run "--bottom" "95" "$run_cmd; exit"
    ;;
  "lazygit")
    split_pane_run "--bottom" "95" "lazygit; exit"
    ;;
  "git_branch_delete")
    split_pane_run "--bottom" "95" "hx-branch-delete.sh; exit"
    ;;
  "open_terminal_bottom")
    wezterm cli split-pane --bottom --percent 25 --cwd "$current_dir"
    ;;
  "open_terminal_right")
    wezterm cli split-pane --right --percent 35 --cwd "$current_dir"
    ;;
  "string_replace")
    split_pane_run "--bottom" "95" "fzf-rg-replace.sh; exit"
    ;;
  "file_replace")
    split_pane_run "--bottom" "95" "fzf-fd-replace.sh; exit"
    ;;
  "bookmark_add")
    hx-bookmark.sh add "$file_path" "$cursor_line"
    ;;
  "bookmark_open")
    split_pane_run "--bottom" "95" "hx-bookmark.sh open; exit"
    ;;
  "bookmark_remove")
    split_pane_run "--bottom" "95" "hx-bookmark.sh remove; exit"
    ;;
  "reveal_workspace")
    open .
    ;;
  "reveal_current_folder")
    open "$basedir"
    ;;
  "open_in_vscode")
    code .
    ;;
  "explorer")
    wezterm cli activate-pane-direction up
    left_pane_id=$(wezterm cli get-pane-direction left)
    if [ -z "${left_pane_id}" ]; then
      left_pane_id=$(wezterm cli split-pane --left --percent 20)
    fi
    left_program=$(wezterm cli list | awk -v pane_id="$left_pane_id" '$3==pane_id { print $6 }')
    if [ "$left_program" != "br" ]; then
      send_to_pane "$left_pane_id" "broot; exit"
    fi
    activate_pane "left" "$left_pane_id"
    ;;
  "fzf")
    # Bash array syntax requires #!/bin/bash
    FZF_ARGS=(
      "--prompt='Search> '"
      --disabled
      --reverse
      "--delimiter :"
      "--bind 'change:reload:fzf-rg.sh {q}'"
      "--bind 'ctrl-r:execute(fzf-rg-replace.sh {q} 1)'"
      "--bind 'ctrl-f:execute(fzf-fd-replace.sh {q} 1)'"
      "--preview 'fzf-bat.sh {2} {1}'"
      "--preview-window '~3,+{2}+3/2'"
      "--border=bottom"
      "--header=$'CTRL-R: replace string | CTRL-F replace files and folder \nENTER: open | -p <path> to scope'"
    )
    # Join array arguments safely
    run_cmd="hx-open.sh \$(fzf-rg.sh | fzf ${FZF_ARGS[*]} | awk '{print \$1}' | cut -d: -f1,2,3)"
    split_pane_run "--bottom" "95" "$run_cmd; exit"
    ;;
  "jq")
    bottom_pane_id=$(split_pane_down)
    send_to_pane "$bottom_pane_id" "echo '$(pbpaste)' | jq"
    ;;
  "run")
    bottom_pane_id=$(split_pane_down)
    case "$extension" in
      "c")
        run_command="clang -lcmocka -lmpfr -Wall -g -O1 $filename -o $basedir/$basename_without_extension && $basedir/$basename_without_extension"
        ;;
      "go")
        run_command="go run $basedir/*.go"
        ;;
      "md")
        run_command="mdcat -p $filename"
        ;;
      "rkt" | "scm")
        run_command="racket $filename"
        ;;
      "rs")
        # Fixed logic: Use Zsh syntax for the check (if [ $? -eq 0 ]; then ... fi) instead of Fish syntax
        # Also fixed the sed logic to ensure it cd's correctly
        project_root=$(echo "$filename" | sed 's|src/.*$||')
        run_command="cd \"$current_dir/$project_root\" && cargo run && wezterm cli activate-pane-direction up"
        ;;
      "sh")
        run_command="sh $filename"
        ;;
      *)
        run_command="echo 'No runner configured for .$extension extension'"
        ;;
    esac
    if [ -n "$run_command" ]; then
      send_to_pane "$bottom_pane_id" "$run_command"
    fi
    ;;
esac
