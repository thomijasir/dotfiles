#!/usr/bin/env sh

# fpath="$1"

# pane_id=$(wezterm cli get-pane-direction up)
# if [ -z "${pane_id}" ]; then
#   pane_id=$(wezterm cli split-pane --up --percent 80)
# fi

# program=$(wezterm cli list --format json | jq --arg pane_id $pane_id -r '.[] | select(.pane_id  == ($pane_id | tonumber)) | .title' | awk '{ print $1 }')
# program_name=$(basename $program)
# if [ "$program_name" = "hx" ]; then
#   printf ":open '%s'\r" "$fpath" | wezterm cli send-text --pane-id "$pane_id" --no-paste
# else
#   printf "hx ${fpath}" | wezterm cli send-text --pane-id "$pane_id" --no-paste
# fi

# wezterm cli activate-pane-direction --pane-id $pane_id up

# Get the most recent window id
# pane_focus="$(wezterm cli list-clients --format json | jq -r '.[0].focused_pane_id')"
# pane_active=$(wezterm cli list --format json | jq --argjson idx "$pane_active_index" -r '.[$idx]')

# Requires: jq, wezterm
# Output: prints the current tab index (0-based) and index+1 (1-based)

# 1) Focused pane id from the most recently interacted client/session
# pane_focus="$(wezterm cli list-clients --format json \
#   | jq -r '.[0].focused_pane_id')"

# if [[ -z "$pane_focus" || "$pane_focus" == "null" ]]; then
#   echo "Unable to determine focused pane (no clients?)." >&2
#   exit 1
# fi

# # 2) Pull the full list (windows/tabs/panes) once
# list_json="$(wezterm cli list --format json)"

# # Resolve window_id and tab_id for the focused pane
# window_id="$(jq -r --arg pid "$pane_focus" \
#   '.[] | select(.pane_id == ($pid|tonumber)) | .window_id' <<<"$list_json")"

# tab_id="$(jq -r --arg pid "$pane_focus" \
#   '.[] | select(.pane_id == ($pid|tonumber)) | .tab_id' <<<"$list_json")"

# if [[ -z "$window_id" || -z "$tab_id" || "$window_id" == "null" || "$tab_id" == "null" ]]; then
#   echo "Unable to resolve window/tab for pane $pane_focus." >&2
#   exit 1
# fi

# # 3) Build the tab_id list for this window, preserving order and removing duplicates
# #    We filter rows by window_id, then take .tab_id, then unique while preserving first occurrence.
# #    jq's unique does not preserve order; we implement order-preserving unique manually.
# tab_list="$(jq -r --arg wid "$window_id" '
#   [ .[]
#     | select(.window_id == ($wid|tonumber))
#     | .tab_id ]
#   | reduce .[] as $t ( []; if (index($t) == null) then . + [$t] else . end )
# ' <<<"$list_json")"

# # Compute 0-based index of current tab_id within tab_list
# index="$(jq -r --arg tid "$tab_id" '
#   def idx_of(arr; x):
#     (arr | to_entries[] | select(.value == (x|tonumber)) | .key)
#     // -1;  # -1 if not found

#   idx_of(.; $tid)
# ' <<<"$tab_list")"

# if [[ "$index" -lt 0 ]]; then
#   echo "Current tab_id $tab_id not found in tab list for window $window_id." >&2
#   exit 1
# fi

# wezterm cli spawn
# wezterm cli activate-tab --tab-index 0

# Spawn a pane in that window (the CLI uses current pane by default; --window-id helps when multiple instances exist)
# wezterm cli split-pane --window-id "$WIN_ID" --right --percent 50
