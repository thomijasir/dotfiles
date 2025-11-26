#!/bin/sh

# Original Scripts
# Author Thomi Jasir (thomijasir@gmail.com)

set -x

command_prompt="$1"
file_path="$2"
cursor_line="$3"
hx_pane_id=$(echo $WEZTERM_PANE)
pwd=$(PWD)
basedir=$(dirname "$filename")
basename=$(basename "$filename")
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

case "$command_prompt" in
  "blame")
    split_pane_down
    echo "tig blame $file_path +$cursor_line; exit" | $send_to_bottom_pane
    ;;
  "check")
    split_pane_down
    case "$extension" in
      "rs")
        run_command="cd $pwd/$(echo $filename | sed 's|src/.*$||'); cargo check; if [ \$status = 0 ]; wezterm cli activate-pane-direction up; end;"
        ;;
    esac
    echo "$run_command" | $send_to_bottom_pane
    ;;
  "yazi")
    split_pane_down
    run_command='tmp="$(mktemp -t yazi-chooser.XXXXXX)"; yazi "$PWD" --chooser-file="$tmp"; [ -s "$tmp" ] && hx-yazi.sh "$(head -n1 "$tmp")"; rm -rf "$tmp"'
    echo "$run_command; exit" | $send_to_bottom_pane
    ;;
  "explorer")
    wezterm cli activate-pane-direction up

    left_pane_id=$(wezterm cli get-pane-direction left)
    if [ -z "${left_pane_id}" ]; then
      left_pane_id=$(wezterm cli split-pane --left --percent 20)
    fi

    left_program=$(wezterm cli list | awk -v pane_id="$left_pane_id" '$3==pane_id { print $6 }')
    if [ "$left_program" != "br" ]; then
      echo "br; exit" | wezterm cli send-text --pane-id $left_pane_id --no-paste
    fi

    wezterm cli activate-pane-direction left
    ;;
  "fzf")
    split_pane_down
    echo "hx-fzf.sh \$(rg --line-number --column --no-heading --smart-case . | fzf --delimiter : --preview 'bat --style=full --color=always --highlight-line {2} {1}' --preview-window '~3,+{2}+3/2' | awk '{ print \$1 }' | cut -d: -f1,2,3)" | $send_to_bottom_pane
    ;;
  "jq")
    split_pane_down
    echo "echo '$(pbpaste)' | jq" | $send_to_bottom_pane
    ;;
  "lazygit")
    split_pane_down
    program=$(wezterm cli list | awk -v pane_id="$pane_id" '$3==pane_id { print $6 }')
    if [ "$program" = "lazygit" ]; then
      wezterm cli activate-pane-direction down
    else
      echo "lazygit; exit" | $send_to_bottom_pane
    fi
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
  "generate_tests")
    split_pane_down
    case "$extension" in
      "go")
        echo "gotests -w -all $filename" | $send_to_bottom_pane
        run_command="echo -e \":open $basedir/${basename_without_extension}_test.go\\\r\" | $send_to_hx_pane; $switch_to_hx_pane_and_zoom"
        echo "$run_command" | $send_to_bottom_pane
        ;;
    esac
    ;;
  "test_all")
    split_pane_down
    case "$extension" in
      "go")
        run_command="go test -v ./...; if [ \$status = 0 ]; wezterm cli activate-pane-direction up; end;"
        ;;
      "rs")
        run_command="cd $pwd/$(echo $filename | sed 's|src/.*$||'); cargo test; if [ \$status = 0 ]; wezterm cli activate-pane-direction up; end;"
        ;;
    esac
    echo "$run_command" | $send_to_bottom_pane
    ;;
  "test_single")
    split_pane_down
    case "$extension" in
      "go")
        test_name=$(head -$line_number $filename | tail -1 | sed -n 's/func \([^(]*\).*/\1/p')
        run_command="go test -run=$test_name -v ./$basedir/...; if [ \$status = 0 ]; wezterm cli activate-pane-direction up; end;"
        ;;
      "rs")
        test_name=$(head -$line_number $filename | tail -1 | sed -n 's/^.*fn \([^ ]*\)().*$/\1/p')
        run_command="cd $pwd/$(echo $filename | sed 's|src/.*$||'); cargo test $test_name; if [ \$status = 0 ]; wezterm cli activate-pane-direction up; end;"
        ;;
    esac
    echo "$run_command" | $send_to_bottom_pane
    ;;
esac
