#!/bin/sh

# Original Scripts
# Author Thomi Jasir (thomijasir@gmail.com)

set -x

command_prompt="$1"
file_path="$2"
cursor_line="$3"
hx_pane_id=$(echo $WEZTERM_PANE)
pwd=$(PWD)
basedir=$(dirname "$file_path")
basename=$(basename "$file_path")
basename_without_extension="${basename%.*}"
extension="${filename##*.}"

send_to_hx_pane="wezterm cli send-text --pane-id $hx_pane_id --no-paste"
switch_to_hx_pane_and_zoom="if [ \$status = 0 ]; wezterm cli activate-pane-direction up; wezterm cli zoom-pane --pane-id $hx_pane_id --zoom; end"

split_pane_down() {
  bottom_pane_id=$(wezterm cli get-pane-direction down)
  if [ -z "${bottom_pane_id}" ]; then
    # minimum load zsh to fast open
    bottom_pane_id=$(wezterm cli split-pane -- zsh -f)
  fi

  wezterm cli activate-pane-direction --pane-id $bottom_pane_id down

  send_to_bottom_pane="wezterm cli send-text --pane-id $bottom_pane_id --no-paste"
  program=$(wezterm cli list | awk -v pane_id="$bottom_pane_id" '$3==pane_id { print $6 }')
  if [ "$program" = "lazygit" ]; then
    echo "q" | $send_to_bottom_pane
  fi
}

split_pane_down_full() {
  wezterm cli split-pane --bottom --percent 95 --cwd $PWD -- zsh -fc "$1; exit"
}

split_pane_down_half() {
  wezterm cli split-pane --bottom --cwd $PWD -- zsh -fc "$1; exit"
}

case "$command_prompt" in
  "ai_gemini")
    # Note: you can configure for claude, open code and any other ai tools
    wezterm cli split-pane --right --percent 40 --cwd $PWD -- zsh -i -c -lc 'gemini; exit'
    ;;
  "ai_claude")
    wezterm cli split-pane --right --percent 40 --cwd $PWD -- zsh -i -c -lc 'claude; exit'
    ;;
  "blame")
    split_pane_down_half "tig blame $file_path +$cursor_line"
    ;;
  "yazi")
    run_cmd='tmp="$(mktemp -t yazi-chooser.XXXXXX)"; yazi "$PWD" --chooser-file="$tmp"; [ -s "$tmp" ] && hx-open.sh "$(head -n1 "$tmp")"; rm -rf "$tmp"'
    split_pane_down_full "$run_cmd"
    ;;
  "lazygit")
    split_pane_down_full "lazygit"
    ;;
  "open_terminal_bottom")
    wezterm cli split-pane --bottom --percent 25 --cwd $PWD
    ;;
  "open_terminal_right")
    wezterm cli split-pane --right --percent 35 --cwd $PWD
    ;;
  "string_replace")
    split_pane_down_full "replace-str.sh"
    ;;
  "file_replace")
    split_pane_down_full "replace-file.sh"
    ;;
  "bookmark_add")
    hx-bookmark.sh add $file_path $cursor_line
    ;;
  "bookmark_open")
    split_pane_down_full "hx-bookmark.sh open"
    ;;
  "bookmark_remove")
    split_pane_down_full "hx-bookmark.sh remove"
    ;;
  "reveal_workspace")
    open .
    ;;
  "reveal_current_folder")
    open $basedir
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
      echo "broot; exit" | wezterm cli send-text --pane-id $left_pane_id --no-paste
    fi
    wezterm cli activate-pane-direction left
    ;;
  "fzf")
    run_cmd="hx-open.sh \$(hx-ripgrep.sh | fzf --disabled --bind 'change:reload:hx-ripgrep.sh {q}' --delimiter : --reverse --preview 'bat --style=full --color=always --highlight-line {2} {1}' --preview-window '~3,+{2}+3/2' | awk '{print \$1}' | cut -d: -f1,2,3)"
    split_pane_down_full "$run_cmd"
    ;;
  "jq")
    split_pane_down
    echo "echo '$(pbpaste)' | jq" | $send_to_bottom_pane
    ;;
  "run")
    split_pane_down
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
        run_command="cd $pwd/$(echo $filename | sed 's|src/.*$||'); cargo run; if [ \$status = 0 ]; wezterm cli activate-pane-direction up; end"
        ;;
      "sh")
        run_command="sh $filename"
        ;;
    esac
    echo "$run_command" | $send_to_bottom_pane
    ;;
esac
