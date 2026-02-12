#!/usr/bin/env bash

# Function to display usage
usage() {
    echo "Usage: $0 --path <current_file_path> [--root|--down]"
    echo "  --path : The full path of the current file context."
    echo "  --root : Create the new file relative to the git root of the current file."
    echo "  --down : Create the new file relative to the directory of the current file (default)."
    exit 1
}

# Parse arguments
PATH_ARG=""
MODE="down" # Default mode

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --path)
            PATH_ARG="$2"
            shift 2
            ;;
        --root)
            MODE="root"
            shift
            ;;
        --down)
            MODE="down"
            shift
            ;;
        *)
            echo "Unknown parameter passed: $1"
            usage
            ;;
    esac
done

# Validate required arguments
if [[ -z "$PATH_ARG" ]]; then
    echo "Error: --path argument is required."
    usage
fi

# Determine reference directory
if [[ -f "$PATH_ARG" ]]; then
    REF_DIR=$(dirname "$PATH_ARG")
else
    # If path arg is a directory or doesn't exist, try to use it as dir or fallback to pwd
    if [[ -d "$PATH_ARG" ]]; then
        REF_DIR="$PATH_ARG"
    else
        # If the file doesn't exist, assume the parent directory is the intended target.
        REF_DIR=$(dirname "$PATH_ARG")
    fi
fi

# Determine Base Directory based on Mode
BASE_DIR=""

if [[ "$MODE" == "root" ]]; then
    # Try to find git root
    if git -C "$REF_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        BASE_DIR=$(git -C "$REF_DIR" rev-parse --show-toplevel)
    else
        echo "Warning: Not in a git repository. Falling back to file directory."
        BASE_DIR="$REF_DIR"
    fi
else
    # Down mode (default)
    BASE_DIR="$REF_DIR"
fi

# Show usage and base directory
echo "Supports directory creation (e.g., folder/file.ts)"
echo "Base: $BASE_DIR"

# Prompt for new filename
# Using /dev/tty to ensure we read from user input even if script is piped or in weird context
if [ -t 0 ]; then
    read -p "Create new file (relative to base): " NEW_FILENAME
else
    # Fallback for non-interactive shells (like tests)
    read NEW_FILENAME
fi

if [[ -z "$NEW_FILENAME" ]]; then
    echo "No filename provided. Aborting."
    exit 1
fi

FULL_PATH="$BASE_DIR/$NEW_FILENAME"
TARGET_DIR=$(dirname "$FULL_PATH")

# Create directory if it doesn't exist
if [[ ! -d "$TARGET_DIR" ]]; then
    echo "Creating directory: $TARGET_DIR"
    mkdir -p "$TARGET_DIR"
fi

# Create empty file if it doesn't exist
if [[ -e "$FULL_PATH" ]]; then
    echo "File already exists: $FULL_PATH"
else
    touch "$FULL_PATH"
    echo "Created file: $FULL_PATH"
fi

# Open the file using hx-open.sh
if command -v hx-open.sh >/dev/null 2>&1; then
    hx-open.sh "$FULL_PATH"
else
    echo "hx-open.sh not found in PATH."
fi

