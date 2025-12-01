#!/bin/bash

# ==============================================================================
# SMART VIDEO COMPRESSOR
# Requirements: ffmpeg, ffprobe
# ==============================================================================

# --- Colors for Output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# --- Check Dependencies ---
if ! command -v ffmpeg &>/dev/null; then
  echo -e "${RED}Error: ffmpeg is not installed.${NC} Please install it first."
  exit 1
fi
if ! command -v ffprobe &>/dev/null; then
  echo -e "${RED}Error: ffprobe is not installed.${NC} Please install it first."
  exit 1
fi

# --- Default Settings ---
COMPRESSION_MODE="maximum" # Default setting
REPLACE=false
INPUT_FILE=""
OUTPUT_FOLDER=""

# --- Help / Usage ---
usage() {
  echo -e "${CYAN}Usage:${NC} $0 [OPTIONS] <video_file> [output_folder]"
  echo ""
  echo "Options:"
  echo "  -m    Maximum Compression (Default). Smallest file. Max 720p. Mono Audio."
  echo "  -s    Standard Compression. Better quality. Max 1080p. Stereo Audio."
  echo "  -r    Replace the original file."
  echo "  -h    Show this help message."
  echo ""
  echo "Example:"
  echo "  $0 video.mp4            (Runs maximum compression)"
  echo "  $0 -s video.mov         (Runs standard compression)"
  echo "  $0 -r video.mp4         (Overwrites original file)"
  echo "  $0 video.mp4 ./out/     (Saves to ./out/video.mp4)"
  exit 1
}

# --- Parse Arguments ---
while getopts "msrh" opt; do
  case ${opt} in
    m)
      COMPRESSION_MODE="maximum"
      ;;
    s)
      COMPRESSION_MODE="standard"
      ;;
    r)
      REPLACE=true
      ;;
    h)
      usage
      ;;
    \?)
      echo -e "${RED}Invalid option: -$OPTARG${NC}" 1>&2
      usage
      ;;
  esac
done
shift $((OPTIND - 1))

INPUT_FILE="$1"
OUTPUT_FOLDER="$2"

# --- Input Validation ---
if [ -z "$INPUT_FILE" ]; then
  echo -e "${RED}Error: No input file specified.${NC}"
  usage
fi

if [ ! -f "$INPUT_FILE" ]; then
  echo -e "${RED}Error: File '$INPUT_FILE' not found.${NC}"
  exit 1
fi

# --- Path and Filename logic ---
DIRNAME=$(dirname "$INPUT_FILE")
BASENAME=$(basename "$INPUT_FILE")
FILENAME="${BASENAME%.*}"
EXTENSION="${BASENAME##*.}"

if [ "$REPLACE" = true ]; then
  OUTPUT_FILE="$INPUT_FILE"
else
  if [ -n "$OUTPUT_FOLDER" ]; then
    mkdir -p "$OUTPUT_FOLDER"
    # Remove trailing slash if present
    OUTPUT_FOLDER=${OUTPUT_FOLDER%/}
    OUTPUT_FILE="${OUTPUT_FOLDER}/${BASENAME}"
  else
    OUTPUT_FILE="${DIRNAME}/${FILENAME}_compressed.${EXTENSION}"
  fi
fi

# --- OS Detection & Optimization ---
OS_TYPE=$(uname -s)
NICE_CMD=""

echo -e "${BLUE}Detecting System Environment...${NC}"
case "$OS_TYPE" in
  Darwin*)
    echo -e "System: ${CYAN}macOS${NC}"
    # macOS specific optimization if needed
    NICE_CMD="nice -n 10" # Lower priority to keep UI responsive
    ;;
  Linux*)
    echo -e "System: ${CYAN}Linux${NC}"
    NICE_CMD="nice -n 10" # Lower priority to keep UI responsive
    ;;
  CYGWIN* | MINGW* | MSYS*)
    echo -e "System: ${CYAN}Windows (Git Bash/Cygwin)${NC}"
    # Windows doesn't use 'nice' effectively in git bash usually, rely on default
    NICE_CMD=""
    ;;
  *)
    echo -e "System: ${CYAN}Unknown ($OS_TYPE)${NC}"
    ;;
esac

# Check for WSL (Windows Subsystem for Linux)
if grep -q Microsoft /proc/version 2>/dev/null; then
  echo -e "Environment: ${CYAN}WSL (Windows Subsystem for Linux)${NC}"
fi

# --- Get File Information (ffprobe) ---
echo -e "${BLUE}Analyzing source file...${NC}"

# Get file size in bytes
ORIG_SIZE=$(wc -c <"$INPUT_FILE")
# Get duration, resolution, codec
DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$INPUT_FILE")
RESOLUTION=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 "$INPUT_FILE")
CODEC=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$INPUT_FILE")

# Helper to format bytes to human readable
human_filesize() {
  awk -v sum="$1" ' BEGIN {hum[1024^3]="GB"; hum[1024^2]="MB"; hum[1024]="KB"; for (x=1024^3; x>=1024; x/=1024) { if (sum>=x) { printf "%.2f %s\n", sum/x, hum[x]; break } } }'
}
ORIG_SIZE_HR=$(human_filesize $ORIG_SIZE)

# --- Define Compression Parameters ---

# NOTE: We stick to libx264 (Software Encoding) even on powerful machines because
# hardware encoders (nvenc, videotoolbox) are generally LESS efficient at
# extremely low bitrates/file sizes than x264 veryslow/CRF.

if [ "$COMPRESSION_MODE" == "maximum" ]; then
  MODE_LABEL="MAXIMUM COMPRESSION (Screen/Log optimized)"
  # Logic:
  # - CRF 30: High compression, noticeable quality drop but watchable.
  # - Preset veryslow: FFMPEG tries harder to compress efficiently.
  # - Scale: Limit width to 100px, keep aspect ratio.
  # - Audio: Mono (ac 1), 64k bitrate (enough for voice).
  # - FPS: Cap at 30 to save frames on high refresh rate videos.
  FFMPEG_ARGS=(
    -c:v libx264
    -preset veryslow
    -crf 30
    -vf "scale='min(1000,iw)':-2,fps=30"
    -c:a aac -b:a 64k -ac 1
    -movflags +faststart
  )
else
  MODE_LABEL="STANDARD COMPRESSION (Media optimized)"
  # Logic:
  # - CRF 26: Decent balance for web sharing.
  # - Preset slower: Good balance of speed vs size.
  # - Scale: Limit width to 1920 (1080p).
  # - Audio: Stereo, 128k.
  FFMPEG_ARGS=(
    -c:v libx264
    -preset slower
    -crf 26
    -vf "scale='min(1920,iw)':-2"
    -c:a aac -b:a 128k -ac 2
    -movflags +faststart
  )
fi

# --- Show Start Info ---
echo -e "=================================================="
echo -e "  ${YELLOW}VIDEO COMPRESSION STARTED${NC}"
echo -e "=================================================="
echo -e "File:         ${INPUT_FILE}"
echo -e "Resolution:   ${RESOLUTION}"
echo -e "Original Size:${ORIG_SIZE_HR}"
echo -e "Original Codec:${CODEC}"
echo -e "Mode:         ${GREEN}${MODE_LABEL}${NC}"
echo -e "Output:       ${OUTPUT_FILE}"
echo -e "=================================================="
echo -e "${CYAN}Processing... (This may take time based on CPU)${NC}"

# --- Execute FFmpeg ---
# Use a temporary file to avoid corruption if reading/writing same file
TEMP_FILE="${OUTPUT_FILE}.tmp.${EXTENSION}"

# We use -stats to show progress line, -y to overwrite if exists
# We use $NICE_CMD to ensure the system stays responsive during 'veryslow' encoding
$NICE_CMD ffmpeg -v error -stats -i "$INPUT_FILE" "${FFMPEG_ARGS[@]}" -y "$TEMP_FILE"

STATUS=$?

echo "" # New line after ffmpeg stats

if [ $STATUS -eq 0 ]; then
  # Move temp file to final destination
  mv "$TEMP_FILE" "$OUTPUT_FILE"

  # --- Summarize ---
  NEW_SIZE=$(wc -c <"$OUTPUT_FILE")
  NEW_SIZE_HR=$(human_filesize $NEW_SIZE)

  # Calculate percentage reduction
  if [ $ORIG_SIZE -gt 0 ]; then
    SAVED_BYTES=$((ORIG_SIZE - NEW_SIZE))
    PERCENT_SAVED=$(awk "BEGIN {printf \"%.1f\", ($SAVED_BYTES / $ORIG_SIZE) * 100}")
  else
    PERCENT_SAVED=0
  fi

  echo -e "=================================================="
  echo -e "  ${GREEN}COMPRESSION COMPLETE${NC}"
  echo -e "=================================================="
  echo -e "Original Size: ${ORIG_SIZE_HR}"
  echo -e "New Size:      ${GREEN}${NEW_SIZE_HR}${NC}"
  echo -e "Reduction:     ${YELLOW}-${PERCENT_SAVED}%${NC}"
  echo -e "Saved Location:${OUTPUT_FILE}"
  echo -e "=================================================="
else
  echo -e "${RED}Compression failed!${NC}"
  rm -f "$TEMP_FILE" # Clean up partial file
  exit 1
fi
