#!/usr/bin/env bash
set -euo pipefail

# --- prerequisites ------------------------------------------------------------
need() { command -v "$1" >/dev/null 2>&1 || {
  echo "Missing dependency: $1" >&2
  exit 1
}; }
need rg
need fzf
need sed

# Check if bat exists, else fallback to cat
if command -v bat >/dev/null 2>&1; then
  PREVIEW_CMD='bat --style=numbers --color=always --highlight-line {2} {1}'
else
  PREVIEW_CMD='cat {1} | nl | sed -n "{2}p"'
fi

# --- inputs -------------------------------------------------------------------
TARGET_DIR="${1:-.}"
echo
echo -e "Search is literal by default.\nUse regex by starting your query with: r=<regex>"
read -r -p "> " RAW_QUERY
if [ -z "${RAW_QUERY}" ]; then
  echo "Empty query. Exiting."
  exit 0
fi

# Determine literal vs regex
QUERY=""
RG_FLAGS=(-n -H --no-heading --color=never -S)
if [[ "${RAW_QUERY}" == r=* ]]; then
  QUERY="${RAW_QUERY#r=}"
else
  QUERY="${RAW_QUERY}"
  RG_FLAGS+=(-F)
fi

# --- collect matches ----------------------------------------------------------
MATCHES="$(
  rg "${RG_FLAGS[@]}" -- "$QUERY" "$TARGET_DIR" || true
)"

if [ -z "${MATCHES}" ]; then
  echo "No matches found."
  exit 0
fi

# Reduce to path:line
MATCHES="$(echo "$MATCHES" | awk -F: '{print $1 ":" $2}' | sort -u)"

# --- interactive selection ----------------------------------------------------
SELECTED="$(
  printf '%s\n' "$MATCHES" |
    fzf --multi \
      --delimiter ':' \
      --preview "$PREVIEW_CMD" \
      --preview-window 'right:60%' \
      --bind 'ctrl-a:toggle-all' \
      --header '🔍 Ctrl-A: Toggle all selections | Enter: Confirm | Esc: Cancel'
)"

if [ -z "${SELECTED}" ]; then
  echo "No selection made. Exiting."
  exit 0
fi

# --- show target files --------------------------------------------------------
FILES="$(printf '%s\n' "$SELECTED" | cut -d: -f1 | sort -u)"
COUNT_FILES="$(printf '%s\n' "$FILES" | sed '/^$/d' | wc -l | tr -d ' ')"
COUNT_MATCHES="$(printf '%s\n' "$SELECTED" | sed '/^$/d' | wc -l | tr -d ' ')"

echo
echo "📋Files to be modified ($COUNT_FILES):"
printf '%s\n' "$FILES"
echo
echo "Total matches selected: $COUNT_MATCHES"
echo

# --- replacement input --------------------------------------------------------
echo -e "Replacement string (only matched portion will be replaced):"
read -r -p "> " REPLACEMENT
ESCAPED_REPL=$(printf '%s' "$REPLACEMENT" | sed -e 's/[\/&]/\\&/g' -e 's/\\/\\\\/g')

# --- dry-run preview ----------------------------------------------------------

echo
echo -e "\033[1;36m🔍 Dry-run preview of replacements:\033[0m"
printf '%s\n' "$SELECTED" | while IFS=: read -r FILE LINE; do
  if [[ "$LINE" =~ ^[0-9]+$ ]]; then
    ORIGINAL=$(sed -n "${LINE}p" "$FILE")
    MODIFIED=$(echo "$ORIGINAL" | sed "s/${QUERY}/${ESCAPED_REPL}/g")

    # Colors
    FILE_COLOR="\033[1;34m"     # Blue for file name
    LINE_COLOR="\033[1;33m"     # Yellow for line number
    ORIGINAL_COLOR="\033[0;31m" # Red for original
    MODIFIED_COLOR="\033[0;32m" # Green for modified
    RESET="\033[0m"

    echo -e "${FILE_COLOR}${FILE}${RESET}:${LINE_COLOR}${LINE}${RESET}"
    echo -e "  ${ORIGINAL_COLOR}- Original:${RESET} $ORIGINAL"
    echo -e "  ${MODIFIED_COLOR}+ Modified:${RESET} $MODIFIED"
  fi
done

echo
read -r -p "Apply changes? [y/N]: " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo "Cancelled."
  exit 0
fi

# --- apply replacements -------------------------------------------------------
if sed --version >/dev/null 2>&1; then
  SED_INPLACE=(-i)
else
  SED_INPLACE=(-i '')
fi

echo
echo -e "\033[1;36mApplying replacements...\033[0m"
i=0
printf '%s\n' "$SELECTED" | while IFS=: read -r FILE LINE; do
  if [[ "$LINE" =~ ^[0-9]+$ ]]; then
    sed "${SED_INPLACE[@]}" "${LINE}s/${QUERY}/${ESCAPED_REPL}/g" "$FILE"
    i=$((i + 1))
    echo -ne "\rProgress: $i/$COUNT_MATCHES replaced..."
  fi
done
echo

# --- summary ------------------------------------------------------------------
echo -e "\033[1;32m✅ Replacement complete! $COUNT_MATCHES/$COUNT_MATCHES matches replaced across $COUNT_FILES files.\033[0m"
