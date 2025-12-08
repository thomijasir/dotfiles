#!/usr/bin/env bash

pane_id=$(wezterm cli get-pane-direction up)

cmd=""
if [ "$#" -gt 0 ]; then
  # Build command: :o 'file1' 'file2' 'file3'
  cmd=":o"
  for path in "$@"; do
    cmd="$cmd '$path'"
  done
  cmd="${cmd}\r"

  # send to WezTerm only if command is not empty
  printf "%b" "$cmd" | wezterm cli send-text --pane-id "$pane_id" --no-paste
fi

wezterm cli activate-pane-direction --pane-id "$pane_id" up

# #!/bin/bash

# fpath="$1"

# pane_id=$(wezterm cli get-pane-direction up)
# printf ":o '%s'\r" "$fpath" | wezterm cli send-text --pane-id "$pane_id" --no-paste
# wezterm cli activate-pane-direction --pane-id $pane_id up

# fpath="$1"

# pane_id=$(wezterm cli get-pane-direction right)
# if [ -z "${pane_id}" ]; then
#   pane_id=$(wezterm cli split-pane --right --percent 80)
# fi

# program=$(wezterm cli list --format json | jq --arg pane_id $pane_id -r '.[] | select(.pane_id  == ($pane_id | tonumber)) | .title' | awk '{ print $1 }')
# program_name=$(basename $program)
# if [ "$program_name" = "hx" ]; then
#   printf ":open '%s'\r" "$fpath" | wezterm cli send-text --pane-id "$pane_id" --no-paste
# else
#   printf "hx ${fpath}" | wezterm cli send-text --pane-id "$pane_id" --no-paste
# fi

# wezterm cli activate-pane-direction --pane-id $pane_id right
