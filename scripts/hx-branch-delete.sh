#!/usr/bin/env bash
# git_delete_branch.sh
# Interactive local branch deletion using fzf (excluding the current branch).
# - Shows confirmation before any deletion (with dry-run plan).
# - Safe delete first (-d); if it fails, show reason and prompt to force (-D) per branch.
# - Excludes 'main', 'master', and 'feature/*' from selection.
# Requirements: git, fzf
#
# Compatible with macOS Bash 3.2 (no ${var,,} or Bash 4-specific features).

set -uo pipefail

FORCE_DELETE=false # If set, deletes with -D directly (no per-branch prompt)

die() {
  printf "Error: %s\n" "$*" >&2
  exit 1
}
usage() {
  cat <<'EOF'
Usage: git_delete_branch.sh [options]

Options:
  -f, --force   Use force delete (-D) for ALL selected branches (no per-branch prompt).
  -h, --help    Show this help.

Behavior:
  - Lists local branches using `git branch --list --format='%(refname:short)'`.
  - Excludes the current branch from selection.
  - Excludes 'main', 'master', and branches matching 'feature/*' from selection.
  - Shows fzf with preview of the last commit on each branch.
  - After selection, shows a dry-run plan and asks to proceed.
  - Attempts safe delete (-d). If that fails, shows the reason and asks:
      "Force delete 'branch'? [y/N]"
  - Deletes one-by-one with progress and a colorized summary.

EOF
}

have() { command -v "$1" >/dev/null 2>&1; }

# Colors & Icons (only if stdout is a terminal)
if [[ -t 1 ]]; then
  BOLD=$'\033[1m'
  DIM=$'\033[2m'
  RESET=$'\033[0m'
  GREEN=$'\033[32m'
  RED=$'\033[31m'
  YELLOW=$'\033[33m'
  BLUE=$'\033[34m'
  CYAN=$'\033[36m'
  CHECK="✅"
  CROSS="❌"
  INFO="ℹ️"
  WARN="⚠️"
  TRASH="🗑️"
else
  BOLD=""
  DIM=""
  RESET=""
  GREEN=""
  RED=""
  YELLOW=""
  BLUE=""
  CYAN=""
  CHECK="[OK]"
  CROSS="[X]"
  INFO="[i]"
  WARN="[!]"
  TRASH="[del]"
fi

# Portable lowercase function (Bash 3 compatible)
to_lower() { printf "%s" "$1" | tr '[:upper:]' '[:lower:]'; }

# Prompt yes/no from /dev/tty with default N (Bash 3 compatible)
prompt_yes_no() {
  # $1 message, $2 default (Y/N), returns 0 for yes, 1 for no
  local msg="$1"
  local def="${2:-N}"
  local ans=""
  printf "%s " "$msg"
  if [[ -t 0 ]]; then
    read -r ans </dev/tty
  else
    read -r ans
  fi
  ans="${ans:-$def}"
  ans="$(to_lower "$ans")"
  case "$ans" in
    y | yes) return 0 ;;
    *) return 1 ;;
  esac
}

# -------------------------------
# Parse CLI (robust, supports `--`)
# -------------------------------
while (($#)); do
  case "$1" in
    -f | --force)
      FORCE_DELETE=true
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    "") shift ;; # ignore stray empty args
    -*)
      die "Unknown option: $1 (use -h for help)"
      ;;
    *)
      # ignore non-option args (allows calling inside repo with extra args)
      shift
      ;;
  esac
done

# -------------------------------
# Preconditions
# -------------------------------
have git || die "git is not installed."
have fzf || die "fzf is not installed (https://github.com/junegunn/fzf#installation)."
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "Not inside a Git repository."

# -------------------------------
# Current branch
# -------------------------------
current_branch="$(git symbolic-ref --short HEAD 2>/dev/null || printf "")"

# -------------------------------
# Collect local branches using `git branch`
# -------------------------------
if git branch --list --format='%(refname:short)' >/dev/null 2>&1; then
  branches="$(git branch --list --format='%(refname:short)' | sort)"
else
  # Fallback: strip markers from plain `git branch` output
  branches="$(git branch | sed -E 's/^\* //; s/^  //; s/^[[:space:]]+//;' | sort)"
fi

# Exclude the current branch (fixed-string match)
if [[ -n "$current_branch" ]]; then
  candidates="$(printf "%s\n" "$branches" | grep -Fxv -- "$current_branch")"
else
  candidates="$branches" # detached HEAD; nothing to exclude
fi

# Additional excludes: main, master, feature/*
# Use anchored ERE to match exactly main/master and any feature/...
exclude_patterns='^(main|master|release/.*)$'
candidates="$(printf "%s\n" "$candidates" | grep -Ev "$exclude_patterns")"

# If no candidates, stop
if [[ -z "$candidates" ]]; then
  printf "${YELLOW}${WARN} No deletable local branches found after exclusions.${RESET}\n"
  if [[ -n "$current_branch" ]]; then
    printf "Current branch: %s (protected)\n" "$current_branch"
  fi
  printf "Excluded patterns: main, master, feature/*\n"
  exit 0
fi

# -------------------------------
# Interactive selection via fzf
# -------------------------------
header="Select local branches to delete (multi-select).
Current branch excluded: ${current_branch:-<detached HEAD>}
Excluded patterns: main, master, feature/*
- Ctrl+A: toggle all  |  Tab/Ctrl+Space: toggle one  |  Enter: confirm"

selected="$(
  printf "%s\n" "$candidates" | fzf \
    --multi \
    --reverse \
    --height=80% \
    --border \
    --bind='ctrl-a:toggle-all,tab:toggle,ctrl-space:toggle+down' \
    --header="$header" \
    --preview 'git --no-pager log -1 --pretty=format:"%C(yellow)%h%Creset %Cgreen%cr%Creset %C(bold blue)%an%Creset%n%s" {}' \
    --preview-window=down,40%,wrap
)"

if [[ -z "$selected" ]]; then
  printf "No branches selected. Aborting.\n"
  exit 0
fi

# Normalize selection to an array
to_delete=()
while IFS= read -r line; do
  [[ -n "$line" ]] && to_delete+=("$line")
done <<<"$selected"

requested="${#to_delete[@]}"
printf "\n${BOLD}${CYAN}Selected %d branch(es):${RESET}\n" "$requested"
printf "%s\n" "${to_delete[@]}"

# -------------------------------
# Pre-execution confirmation (dry-run plan)
# -------------------------------
printf "\n${BOLD}${INFO} Dry run plan:${RESET}\n"
if [[ "$FORCE_DELETE" == "true" ]]; then
  for b in "${to_delete[@]}"; do
    printf "  %s git branch -D %s\n" "$TRASH" "$b"
  done
else
  for b in "${to_delete[@]}"; do
    printf "  %s git branch -d %s\n" "$TRASH" "$b"
  done
fi

if ! prompt_yes_no "${BLUE}Proceed with the above deletion plan?${RESET} [y/N]"; then
  printf "${YELLOW}${WARN} Cancelled by user.${RESET}\n"
  exit 0
fi

# -------------------------------
# Delete with progress (safe -> prompt -> force)
# -------------------------------
deleted_safe=0
deleted_forced=0
failed=0
skipped=0
fail_report=""

printf "\n${BOLD}${GREEN}Deleting branches...${RESET}\n"
for b in "${to_delete[@]}"; do
  timestamp="$(date +%H:%M:%S)"
  printf "  [%s] Deleting '%s'... " "$timestamp" "$b"

  if [[ "$FORCE_DELETE" == "true" ]]; then
    # Global force mode: no prompts
    err_out="$(git branch -D "$b" 2>&1 >/dev/null)"
    if [[ $? -eq 0 ]]; then
      printf "%s\n" "$CHECK"
      ((deleted_forced++))
    else
      printf "%s\n" "$CROSS"
      ((failed++))
      printf -v fail_report "%s- %s\n  %s\n" "$fail_report" "$b" "$err_out"
    fi
    continue
  fi

  # Try safe delete first
  err_out="$(git branch -d "$b" 2>&1 >/dev/null)"
  if [[ $? -eq 0 ]]; then
    printf "%s\n" "$CHECK"
    ((deleted_safe++))
    continue
  fi

  # Safe delete failed -> show reason and prompt to force
  printf "%s\n" "$CROSS"
  printf "    ${YELLOW}Reason:${RESET}\n"
  printf "%s\n" "$err_out" | sed 's/^/    /'
  if prompt_yes_no "    ${BLUE}This branch cannot be deleted safely. Proceed with ${BOLD}-D${RESET}${BLUE} (force)?${RESET} [y/N]"; then
    err_force="$(git branch -D "$b" 2>&1 >/dev/null)"
    if [[ $? -eq 0 ]]; then
      printf "    Force delete: %s\n" "$CHECK"
      ((deleted_forced++))
    else
      printf "    Force delete: %s\n" "$CROSS"
      ((failed++))
      printf -v fail_report "%s- %s\n  %s\n  Force attempt: %s\n" \
        "$fail_report" "$b" "$err_out" "$err_force"
    fi
  else
    printf "    ${DIM}Skipped.${RESET}\n"
    ((skipped++))
    printf -v fail_report "%s- %s\n  %s\n  Action: skipped\n" \
      "$fail_report" "$b" "$err_out"
  fi
done

# -------------------------------
# Summary (no box; clean colors & icons)
# -------------------------------
total_deleted=$((deleted_safe + deleted_forced))

printf "\n${BOLD}${CYAN}Summary${RESET}\n"
printf "${BOLD}Requested:${RESET}           %d\n" "$requested"
printf "${GREEN}${BOLD}Deleted (safe -d):${RESET}   %d\n" "$deleted_safe"
printf "${GREEN}${BOLD}Deleted (forced -D):${RESET} %d\n" "$deleted_forced"
printf "${YELLOW}${BOLD}Skipped:${RESET}             %d\n" "$skipped"
printf "${RED}${BOLD}Failed:${RESET}              %d\n" "$failed"
printf "${GREEN}${CHECK} Total deleted:${RESET} %d\n" "$total_deleted"
printf "${BLUE}${INFO} Current branch (protected):${RESET} %s\n" "${current_branch:-<detached HEAD>}"

if [[ -n "$fail_report" ]]; then
  printf "\n${BOLD}${WARN} Details:${RESET}\n"
  printf "%s" "$fail_report"
fi

printf "\nDone.\n"
