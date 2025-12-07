#!/bin/bash

# ==============================================================================
# DESKTOP WATCHER & COMPRESSOR
# Requirements: fswatch, xattr
# ==============================================================================

# --- Configuration ---
WATCH_DIR="$HOME/Desktop"
COMPRESS_VIDEO="compress-video.sh"
COMPRESS_IMAGE="compress-image.sh"

# --- Check Dependencies ---
if ! command -v fswatch &>/dev/null; then
  echo "Error: fswatch is not installed. Please install it (e.g., brew install fswatch)."
  exit 1
fi

if ! command -v xattr &>/dev/null; then
  echo "Error: xattr is not installed. This script requires xattr to prevent infinite loops."
  exit 1
fi

# --- Helper Functions ---
is_processed() {
  # Check for the custom attribute 'com.user.compressed'
  # We suppress stderr to avoid noise if attribute doesn't exist
  xattr -p com.user.compressed "$1" 2>/dev/null | grep -q "true"
}

mark_processed() {
  # Set the custom attribute 'com.user.compressed' to 'true'
  xattr -w com.user.compressed true "$1"
}

# --- Main Loop ---
echo "=================================================="
echo "  DESKTOP COMPRESSION WATCHER"
echo "=================================================="
echo "Watching: $WATCH_DIR"
echo "Target 1: 'Screenshot ... .png' -> compress-image.sh"
echo "Target 2: 'Screen Recording ... .mov' -> compress-video.sh"
echo "Press Ctrl+C to stop."
echo "=================================================="

# Watch for events in the Desktop directory
# -0: Use NUL character as delimiter (handles filenames with spaces)
# We filter strictly in the loop for better control
fswatch -0 "$WATCH_DIR" | while read -d "" event; do

  FILENAME=$(basename "$event")
  FOLDER=$(dirname "$event")
  # 1. Check if file exists (it might have been deleted or moved quickly)
  if [ ! -f "$event" ]; then
    continue
  fi

  # 2. Check filename patterns
  # We only care about macOS default naming conventions for Screenshots and Screen Recordings
  IS_SCREENSHOT=false
  IS_RECORDING=false

  # Regex for macOS default naming convention
  # Example: "Screenshot 2023-12-01 at 10.00.00.png"
  # if [[ "$FILENAME" =~ ^Screenshot\ [0-9]{4}-[0-9]{2}-[0-9]{2}\ at\ .*\.(jpg|jpeg|png)$ ]]; then
  if [[ "$FILENAME" =~ ^.*\.(jpg|jpeg|png)$ ]]; then
    IS_SCREENSHOT=true
  # Example: "Screen Recording 2023-12-01 at 10.00.00.mov"
  elif [[ "$FILENAME" =~ ^Screen\ Recording\ [0-9]{4}-[0-9]{2}-[0-9]{2}\ at\ .*\.mov$ ]]; then
    IS_RECORDING=true
  else
    # Not a target file
    continue
  fi

  # 3. Check if already processed (avoid loops)
  if is_processed "$event"; then
    # Debug: echo "Skipping already processed file: $FILENAME"
    continue
  fi

  # 4. Wait for file to be ready
  # Screenshots/Recordings might be written progressively.
  # A simple sleep helps ensure the file handle is released by the OS.
  sleep 2

  # 5. Process
  STATUS=1
  if [ "$IS_RECORDING" = true ]; then
    echo "[$(date '+%H:%M:%S')] Detected Recording: $FILENAME"
    "$COMPRESS_VIDEO" -r "$event"
    STATUS=$?
  elif [ "$IS_SCREENSHOT" = true ]; then
    echo "[$(date '+%H:%M:%S')] Detected Screenshot: $FILENAME"
    "$COMPRESS_IMAGE" -r "$event"
    STATUS=$?
  fi

  # 6. Mark as processed if successful
  # This is crucial: The compression scripts replace the file.
  # The replacement triggers a new fswatch event.
  # By marking it immediately, the next loop iteration will see the mark and skip it.
  if [ $STATUS -eq 0 ]; then
    mark_processed "$event"
    echo "Done."
    terminal-notifier -title "Compression successful!" -message "$FILENAME" -sound default -open "file://$FOLDER"
  else
    echo "Error compressing $FILENAME"
  fi

done
