#!/usr/bin/env bash
# Rename directories first (deepest -> shallowest), or filenames only, or both.
# fd + fzf selection, dry-run previews, collision checks, transactional rollback.
# UX tweak: if there are no folder renames, show only file preview and prompt Y/N.
set -eEuo pipefail

# --- user toggles --------------------------------------------------------------
# Attempt to remove now-empty old directories after success
CLEAN_EMPTY_ON_SUCCESS=${CLEAN_EMPTY_ON_SUCCESS:-0}

# --- prerequisites -------------------------------------------------------------
need() { command -v "$1" >/dev/null 2>&1 || {
  echo "Missing dependency: $1" >&2
  exit 1
}; }
need fd
need fzf
need sed
need awk
need mv
need mkdir
need dirname
need basename

# Optional: bat for nicer previews
if command -v bat >/dev/null 2>&1; then
  PREVIEW_CMD='bat --style=numbers --color=always --line-range=:200 {}'
else
  PREVIEW_CMD="nl -ba {} | sed -n '1,200p'"
fi

# --- temp files ---------------------------------------------------------------
TMPDIR="$(mktemp -d)"
SEL_FILE="$TMPDIR/selected.txt"
CAND_FILE="$TMPDIR/candidates.txt"

MAP_DIRS="$TMPDIR/dir_map.tsv"             # old_dir \t new_dir
MAP_FILES_BEFORE="$TMPDIR/file_before.tsv" # old_file \t new_file (no dir rename)
MAP_FILES_AFTER="$TMPDIR/file_after.tsv"   # old_file_after_dir \t new_file (after dir rename)

CONFLICTS_DIRS="$TMPDIR/conf_dirs.txt"
CONFLICTS_FILES_BEFORE="$TMPDIR/conf_files_before.txt"
CONFLICTS_FILES_AFTER="$TMPDIR/conf_files_after.txt"

PREVIEW_DIRS="$TMPDIR/preview_dirs.tsv" # rel_dir \t old_name \t new_name
PREVIEW_FILES_BEFORE="$TMPDIR/preview_files_before.tsv"
PREVIEW_FILES_AFTER="$TMPDIR/preview_files_after.tsv"

ROLLBACK="$TMPDIR/rollback.tsv" # new_path \t old_path
COMMITTED=0

cleanup() {
  rm -f "$SEL_FILE" "$CAND_FILE" \
    "$MAP_DIRS" "$MAP_FILES_BEFORE" "$MAP_FILES_AFTER" \
    "$CONFLICTS_DIRS" "$CONFLICTS_FILES_BEFORE" "$CONFLICTS_FILES_AFTER" \
    "$PREVIEW_DIRS" "$PREVIEW_FILES_BEFORE" "$PREVIEW_FILES_AFTER" \
    "$ROLLBACK" 2>/dev/null || true
  rmdir "$TMPDIR" 2>/dev/null || true
}
trap cleanup EXIT

# --- rollback helpers ----------------------------------------------------------
reverse_file() { if command -v tac >/dev/null 2>&1; then tac "$1"; else tail -r "$1"; fi; }
rollback() {
  if [[ -s "$ROLLBACK" && "$COMMITTED" -eq 0 ]]; then
    echo -e "\n\033[0;31mError occurred. Rolling back...\033[0m" >&2
    reverse_file "$ROLLBACK" | while IFS=$'\t' read -r NEW OLD; do
      [[ -e "$NEW" || -L "$NEW" ]] && mv -- "$NEW" "$OLD" && echo "Rolled back: $NEW -> $OLD"
    done
    echo -e "\033[0;31mRollback complete.\033[0m" >&2
  fi
}

# --- utils --------------------------------------------------------------------
escape_sed_replacement() { printf '%s' "$1" | sed -e 's/[&\\/]/\\&/g'; }
escape_regex_literal() { printf '%s' "$1" | sed -E 's/([][$.^?*+(){}\\])/\\\1/g'; }

# Colors & icons (always show icons; disable color if NO_COLOR or low tput)
PATH_C="\033[1;34m"
BEFORE_C="\033[0;31m"
AFTER_C="\033[0;32m"
ARROW_C="\033[1;37m"
RESET="\033[0m"
FOLDER_ICON="📁"
FILE_ICON="-"
ARROW="→"
if [[ -n "${NO_COLOR:-}" || "$(tput colors 2>/dev/null || echo 0)" -lt 8 ]]; then
  PATH_C=""
  BEFORE_C=""
  AFTER_C=""
  ARROW_C=""
  RESET=""
  ARROW="->"
fi

# --- inputs -------------------------------------------------------------------
TARGET_DIR="${1:-.}"

echo
echo -e "Search is \033[1mLITERAL\033[0m by default.
Use regex by starting your query with: r=<regex>
(fd search is case-\033[1minsensitive\033[0m; replacement uses sed)."
read -r -p "> " RAW_QUERY
[[ -z "${RAW_QUERY}" ]] && {
  echo "Empty query. Exiting."
  exit 0
}

FD_FLAGS=(-t f -i)
if [[ "${RAW_QUERY}" == r=* ]]; then
  PATTERN="${RAW_QUERY#r=}"
  is_regex=1
else
  PATTERN="${RAW_QUERY}"
  FD_FLAGS+=(-F)
  is_regex=0
fi

# --- search & select ----------------------------------------------------------
fd "${FD_FLAGS[@]}" -- "${PATTERN}" "${TARGET_DIR}" >"$CAND_FILE" || true
if [[ ! -s "$CAND_FILE" ]]; then
  echo -e "\n\033[0;31mNo filenames matched '\033[1m${RAW_QUERY}\033[0m'.\033[0m"
  exit 1
fi

fzf --multi \
  --preview "$PREVIEW_CMD" \
  --preview-window 'right:60%' \
  --bind 'ctrl-a:toggle-all' \
  --header $'Ctrl-A: Toggle all \nEnter: Confirm \nEsc: Cancel' \
  <"$CAND_FILE" >"$SEL_FILE" || true

[[ ! -s "$SEL_FILE" ]] && {
  echo "No selection made. Exiting."
  exit 0
}

COUNT_SELECTED="$(wc -l <"$SEL_FILE" | tr -d ' ')"
echo
echo -e "\033[1;36m📋 selected files ($COUNT_SELECTED):\033[0m"
cat "$SEL_FILE"

# --- replacement text ---------------------------------------------------------
echo
echo -e "Enter the \033[1mreplacement\033[0m text (what to change \033[1m${RAW_QUERY}\033[0m into):"
read -r -p "> " RAW_REPL
REPL_ESC="$(escape_sed_replacement "$RAW_REPL")"
FROM_ESC="$(escape_regex_literal "$PATTERN")"

# --- build maps ---------------------------------------------------------------
: >"$MAP_DIRS"
: >"$MAP_FILES_BEFORE"
: >"$MAP_FILES_AFTER"

while IFS= read -r FILE; do
  OLD_DIR="$(dirname -- "$FILE")"
  BASE="$(basename -- "$FILE")"

  if [[ $is_regex -eq 1 ]]; then
    NEW_DIR="$(printf '%s' "$OLD_DIR" | sed -E "s/${PATTERN}/${REPL_ESC}/g")"
    NEW_BASE="$(printf '%s' "$BASE" | sed -E "s/${PATTERN}/${REPL_ESC}/g")"
  else
    NEW_DIR="$(printf '%s' "$OLD_DIR" | sed -E "s/${FROM_ESC}/${REPL_ESC}/g")"
    NEW_BASE="$(printf '%s' "$BASE" | sed -E "s/${FROM_ESC}/${REPL_ESC}/g")"
  fi

  # Directory map
  if [[ "$NEW_DIR" != "$OLD_DIR" ]]; then
    printf '%s\t%s\n' "$OLD_DIR" "$NEW_DIR" >>"$MAP_DIRS"
  fi

  # File maps (before-dir and after-dir scenarios)
  if [[ "$NEW_BASE" != "$BASE" ]]; then
    printf '%s\t%s\n' "$OLD_DIR/$BASE" "$OLD_DIR/$NEW_BASE" >>"$MAP_FILES_BEFORE"
    printf '%s\t%s\n' "$NEW_DIR/$BASE" "$NEW_DIR/$NEW_BASE" >>"$MAP_FILES_AFTER"
  fi
done <"$SEL_FILE"

# Dedup directory map (unique rows)
[[ -s "$MAP_DIRS" ]] && sort -u "$MAP_DIRS" -o "$MAP_DIRS"

# --- preflight (three plans) --------------------------------------------------
: >"$CONFLICTS_DIRS"
: >"$CONFLICTS_FILES_BEFORE"
: >"$CONFLICTS_FILES_AFTER"

if [[ -s "$MAP_DIRS" ]]; then
  DUP_DIR_TARGETS="$(cut -f2 "$MAP_DIRS" | sort | uniq -d || true)"
  [[ -n "$DUP_DIR_TARGETS" ]] && {
    echo "Duplicate directory targets:" >>"$CONFLICTS_DIRS"
    printf '%s\n' "$DUP_DIR_TARGETS" >>"$CONFLICTS_DIRS"
  }
  while IFS=$'\t' read -r OD ND; do
    if [[ -e "$ND" && "$ND" != "$OD" ]]; then
      echo "Directory target exists: $ND ← from $OD" >>"$CONFLICTS_DIRS"
    fi
  done <"$MAP_DIRS"
fi

if [[ -s "$MAP_FILES_BEFORE" ]]; then
  DUP_BEFORE="$(cut -f2 "$MAP_FILES_BEFORE" | sort | uniq -d || true)"
  [[ -n "$DUP_BEFORE" ]] && {
    echo "Duplicate file targets (files-only mode):" >>"$CONFLICTS_FILES_BEFORE"
    printf '%s\n' "$DUP_BEFORE" >>"$CONFLICTS_FILES_BEFORE"
  }
  while IFS=$'\t' read -r OF NF; do
    if [[ -e "$NF" && "$NF" != "$OF" ]]; then
      echo "File target exists (files-only): $NF ← from $OF" >>"$CONFLICTS_FILES_BEFORE"
    fi
  done <"$MAP_FILES_BEFORE"
fi

if [[ -s "$MAP_FILES_AFTER" ]]; then
  DUP_AFTER="$(cut -f2 "$MAP_FILES_AFTER" | sort | uniq -d || true)"
  [[ -n "$DUP_AFTER" ]] && {
    echo "Duplicate file targets (after folder rename):" >>"$CONFLICTS_FILES_AFTER"
    printf '%s\n' "$DUP_AFTER" >>"$CONFLICTS_FILES_AFTER"
  }
  while IFS=$'\t' read -r OF NF; do
    if [[ -e "$NF" && "$NF" != "$OF" ]]; then
      echo "File target exists (after folder rename): $NF ← from $OF" >>"$CONFLICTS_FILES_AFTER"
    fi
  done <"$MAP_FILES_AFTER"
fi

# --- build dry-run previews ---------------------------------------------------
# Folders
: >"$PREVIEW_DIRS"
if [[ -s "$MAP_DIRS" ]]; then
  while IFS=$'\t' read -r OD ND; do
    REL_OD="$OD"
    case "$TARGET_DIR" in
      "." | "./") REL_OD="${REL_OD#./}" ;;
      *)
        REL_OD="${REL_OD#"$TARGET_DIR"/}"
        REL_OD="${REL_OD#./}"
        ;;
    esac
    [[ -z "$REL_OD" ]] && REL_OD="."
    printf '%s\t%s\t%s\n' "$REL_OD" "$(basename -- "$OD")" "$(basename -- "$ND")" >>"$PREVIEW_DIRS"
  done <"$MAP_DIRS"
fi

# Files (before-dir)
: >"$PREVIEW_FILES_BEFORE"
if [[ -s "$MAP_FILES_BEFORE" ]]; then
  while IFS=$'\t' read -r OF NF; do
    D="$(dirname -- "$OF")"
    B="$(basename -- "$OF")"
    NB="$(basename -- "$NF")"
    REL_D="$D"
    case "$TARGET_DIR" in
      "." | "./") REL_D="${REL_D#./}" ;;
      *)
        REL_D="${REL_D#"$TARGET_DIR"/}"
        REL_D="${REL_D#./}"
        ;;
    esac
    [[ -z "$REL_D" ]] && REL_D="."
    printf '%s\t%s\t%s\n' "$REL_D" "$B" "$NB" >>"$PREVIEW_FILES_BEFORE"
  done <"$MAP_FILES_BEFORE"
fi

# Files (after-dir)
: >"$PREVIEW_FILES_AFTER"
if [[ -s "$MAP_FILES_AFTER" ]]; then
  while IFS=$'\t' read -r OF NF; do
    D="$(dirname -- "$OF")"
    B="$(basename -- "$OF")"
    NB="$(basename -- "$NF")"
    REL_D="$D"
    case "$TARGET_DIR" in
      "." | "./") REL_D="${REL_D#./}" ;;
      *)
        REL_D="${REL_D#"$TARGET_DIR"/}"
        REL_D="${REL_D#./}"
        ;;
    esac
    [[ -z "$REL_D" ]] && REL_D="."
    printf '%s\t%s\t%s\n' "$REL_D" "$B" "$NB" >>"$PREVIEW_FILES_AFTER"
  done <"$MAP_FILES_AFTER"
fi

# --- print dry-run ------------------------------------------------------------
echo
if [[ -s "$PREVIEW_DIRS" ]]; then
  echo -e "\033[1;36m📁 Dry-run: directory renames (deepest first)\033[0m"
  # One-line format: 📁 REL_PATH- OLDNAME → NEWNAME (hyphen right after path)
  awk -F'\t' '{ split($1,a,"/"); print length(a) "\t" $0 }' "$PREVIEW_DIRS" |
    sort -nr -k1,1 |
    cut -f2- |
    while IFS=$'\t' read -r REL ODNAME NDNAME; do
      printf "%s %b%s%b- %b%s%b %b%s%b %b%s%b\n" \
        "$FOLDER_ICON" "$PATH_C" "$REL" "$RESET" \
        "$BEFORE_C" "$ODNAME" "$RESET" \
        "$ARROW_C" "$ARROW" "$RESET" \
        "$AFTER_C" "$NDNAME" "$RESET"
    done
else
  # Suppress the "No directory names will change" line if we do have file changes;
  # print it only when there are truly no changes at all.
  if ! [[ -s "$PREVIEW_FILES_BEFORE" || -s "$PREVIEW_FILES_AFTER" ]]; then
    echo -e "\033[0;33m(No directory names will change.)\033[0m"
  fi
fi

echo
# Only show the "after folder rename" group if there ARE folder changes.
if [[ -s "$MAP_DIRS" && -s "$PREVIEW_FILES_AFTER" ]]; then
  echo -e "\033[1;36m📄 Dry-run: file basenames (after folder rename)\033[0m"
  CUR_DIR=""
  sort -t $'\t' -k1,1 -k2,2 "$PREVIEW_FILES_AFTER" |
    while IFS=$'\t' read -r REL B NB; do
      if [[ "$REL" != "$CUR_DIR" ]]; then
        [[ -n "$CUR_DIR" ]] && echo
        printf "%s %b%s%b\n" "$FOLDER_ICON" "$PATH_C" "$REL" "$RESET"
        CUR_DIR="$REL"
      fi
      printf " %s %b%s%b %b%s%b %b%s%b\n" \
        "$FILE_ICON" \
        "$BEFORE_C" "$B" "$RESET" \
        "$ARROW_C" "$ARROW" "$RESET" \
        "$AFTER_C" "$NB" "$RESET"
    done
elif [[ -s "$MAP_DIRS" ]]; then
  echo -e "\033[0;33m(No file basenames will change after folder rename.)\033[0m"
fi

if [[ -s "$PREVIEW_FILES_BEFORE" ]]; then
  echo
  # If there are no directory changes, use a generic heading without mode wording.
  if [[ ! -s "$MAP_DIRS" ]]; then
    echo -e "\033[1;36m📄 Dry-run: file basenames\033[0m"
  else
    echo -e "\033[1;36m📄 Dry-run: file basenames (files-only)\033[0m"
  fi
  CUR_DIR=""
  sort -t $'\t' -k1,1 -k2,2 "$PREVIEW_FILES_BEFORE" |
    while IFS=$'\t' read -r REL B NB; do
      if [[ "$REL" != "$CUR_DIR" ]]; then
        [[ -n "$CUR_DIR" ]] && echo
        printf "%s %b%s%b\n" "$FOLDER_ICON" "$PATH_C" "$REL" "$RESET"
        CUR_DIR="$REL"
      fi
      printf " %s %b%s%b %b%s%b %b%s%b\n" \
        "$FILE_ICON" \
        "$BEFORE_C" "$B" "$RESET" \
        "$ARROW_C" "$ARROW" "$RESET" \
        "$AFTER_C" "$NB" "$RESET"
    done
fi

# Show preflight warnings (informational; final check happens per choice)
warn_block() {
  local title="$1" file="$2"
  if [[ -s "$file" ]]; then
    echo -e "\n\033[0;31m⚠ Preflight issues in ${title}:\033[0m"
    cat "$file"
  fi
}
warn_block "FOLDERS" "$CONFLICTS_DIRS"
warn_block "FILES (files-only)" "$CONFLICTS_FILES_BEFORE"
warn_block "FILES (after folder rename)" "$CONFLICTS_FILES_AFTER"

echo

# --- counts first (used to decide the UX path) --------------------------------
COUNT_DIRS="$(wc -l <"$MAP_DIRS" 2>/dev/null | tr -d ' ' || echo 0)"
COUNT_FILES_BEFORE="$(wc -l <"$MAP_FILES_BEFORE" 2>/dev/null | tr -d ' ' || echo 0)"
COUNT_FILES_AFTER="$(wc -l <"$MAP_FILES_AFTER" 2>/dev/null | tr -d ' ' || echo 0)"

# --- nothing to do? -----------------------------------------------------------
if [[ "$COUNT_DIRS" -eq 0 && "$COUNT_FILES_BEFORE" -eq 0 && "$COUNT_FILES_AFTER" -eq 0 ]]; then
  echo -e "\n\033[0;33mNothing to rename.\033[0m"
  exit 0
fi

# --- prompt style: collapse to Y/N when there are no folder changes ----------
if [[ "$COUNT_DIRS" -eq 0 ]]; then
  # Only file renames are possible. Keep it simple.
  read -r -p "Apply file renames? [y/N]: " _yn
  case "${_yn:-N}" in
    [Yy]*)
      APPLY_CHOICE=1
      ;;
    *)
      echo "Aborted."
      exit 0
      ;;
  esac
else
  echo "Apply what?"
  echo " 1) Files only"
  echo " 2) Folders only"
  echo " 3) Both (default)"
  read -r -p "[1/2/3]: " APPLY_CHOICE
  [[ ! "${APPLY_CHOICE:-3}" =~ ^[123]$ ]] && APPLY_CHOICE=3
fi

# --- final preflight per choice ----------------------------------------------
abort_with() {
  echo -e "\n\033[0;31mPreflight FAILED:\033[0m"
  cat "$1"
  exit 1
}
case "$APPLY_CHOICE" in
  1) [[ -s "$CONFLICTS_FILES_BEFORE" ]] && abort_with "$CONFLICTS_FILES_BEFORE" ;;
  2) [[ -s "$CONFLICTS_DIRS" ]] && abort_with "$CONFLICTS_DIRS" ;;
  3)
    [[ -s "$CONFLICTS_DIRS" ]] && abort_with "$CONFLICTS_DIRS"
    [[ -s "$CONFLICTS_FILES_AFTER" ]] && abort_with "$CONFLICTS_FILES_AFTER"
    ;;
esac

# --- apply --------------------------------------------------------------------
trap rollback ERR
echo
if [[ "$APPLY_CHOICE" -eq 2 || "$APPLY_CHOICE" -eq 3 ]]; then
  echo -e "\033[1;36mApplying folder renames...\033[0m"
  if [[ -s "$MAP_DIRS" ]]; then
    i=0
    awk -F'\t' '{ split($1,a,"/"); print length(a) "\t" $0 }' "$MAP_DIRS" |
      sort -nr -k1,1 |
      cut -f2- |
      while IFS=$'\t' read -r OD ND; do
        mkdir -p -- "$(dirname -- "$ND")"
        mv -- "$OD" "$ND"
        printf '%s\t%s\n' "$ND" "$OD" >>"$ROLLBACK"
        i=$((i + 1))
        echo -ne "\rFolders: $i/$COUNT_DIRS ..."
      done
    echo
  else
    echo "(No folder renames to apply.)"
  fi
fi

if [[ "$APPLY_CHOICE" -eq 1 ]]; then
  echo -e "\033[1;36mApplying file renames (files-only)...\033[0m"
  if [[ -s "$MAP_FILES_BEFORE" ]]; then
    j=0
    while IFS=$'\t' read -r OF NF; do
      mkdir -p -- "$(dirname -- "$NF")"
      mv -- "$OF" "$NF"
      printf '%s\t%s\n' "$NF" "$OF" >>"$ROLLBACK"
      j=$((j + 1))
      echo -ne "\rFiles: $j/$COUNT_FILES_BEFORE ..."
    done <"$MAP_FILES_BEFORE"
    echo
  else
    echo "(No file renames to apply.)"
  fi
elif [[ "$APPLY_CHOICE" -eq 3 ]]; then
  echo -e "\033[1;36mApplying file renames (after folder renames)...\033[0m"
  if [[ -s "$MAP_FILES_AFTER" ]]; then
    k=0
    while IFS=$'\t' read -r OF NF; do
      mkdir -p -- "$(dirname -- "$NF")"
      mv -- "$OF" "$NF"
      printf '%s\t%s\n' "$NF" "$OF" >>"$ROLLBACK"
      k=$((k + 1))
      echo -ne "\rFiles: $k/$COUNT_FILES_AFTER ..."
    done <"$MAP_FILES_AFTER"
    echo
  else
    echo "(No file renames to apply.)"
  fi
fi

COMMITTED=1

# --- summary ------------------------------------------------------------------
case "$APPLY_CHOICE" in
  1) echo -e "\033[1;32m✅ Done.\033[0m Files changed: $COUNT_FILES_BEFORE" ;;
  2) echo -e "\033[1;32m✅ Done.\033[0m Folders changed: $COUNT_DIRS" ;;
  3) echo -e "\033[1;32m✅ Done.\033[0m Folders changed: $COUNT_DIRS; Files changed: $COUNT_FILES_AFTER" ;;
esac

# --- optional cleanup of empty old dirs --------------------------------------
if [[ "$CLEAN_EMPTY_ON_SUCCESS" -eq 1 && "$APPLY_CHOICE" -ge 2 && -s "$MAP_DIRS" ]]; then
  echo "Cleaning up now-empty old directories..."
  cut -f1 "$MAP_DIRS" |
    sort -u |
    awk '{ print length($0), $0 }' |
    sort -nr |
    cut -d" " -f2- |
    while read -r d; do rmdir -p "$d" 2>/dev/null || true; done
fi
