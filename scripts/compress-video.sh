#!/bin/bash

# ==============================================================================
# SMART VIDEO COMPRESSOR
# Requirements: ffmpeg, ffprobe
# ==============================================================================

# --- Colors & Icons ---
BOLD='\033[1m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

ICON_INFO="ℹ️"
ICON_SUCCESS="✅"
ICON_ERROR="❌"
ICON_WARN="⚠️"
ICON_VIDEO="🎬"
ICON_SAVE="💾"
ICON_TRASH="🗑️"

# --- Check Dependencies ---
check_dependency() {
  if ! command -v "$1" &>/dev/null; then
    echo -e "${RED}${ICON_ERROR} Error: $1 is not installed.${NC} Please install it first."
    exit 1
  fi
}
check_dependency ffmpeg
check_dependency ffprobe

# --- Default Settings ---
COMPRESSION_MODE="maximum"
REPLACE=false
DELETE_ORIGINAL=false
INPUT_FILE=""
OUTPUT_FOLDER=""

# --- Help / Usage ---
usage() {
  echo -e "${BOLD}${CYAN}Smart Video Compressor${NC}"
  echo -e "${CYAN}Usage:${NC} $0 [OPTIONS] <video_file> [output_folder]"
  echo ""
  echo -e "${BOLD}Options:${NC}"
  echo -e "  ${YELLOW}-m${NC}    Maximum Compression (Default). Max 720p. Mono Audio."
  echo -e "  ${YELLOW}-s${NC}    Standard Compression. Max 1080p. Stereo Audio."
  echo -e "  ${YELLOW}-r${NC}    Replace the original file (overwrite)."
  echo -e "  ${YELLOW}-d${NC}    Delete original file after compression (converts to .mp4)."
  echo -e "  ${YELLOW}-h${NC}    Show this help message."
  echo ""
  echo -e "${BOLD}Examples:${NC}"
  echo -e "  $0 video.mp4            ${BLUE}# Max compression${NC}"
  echo -e "  $0 -s video.mov         ${BLUE}# Standard compression${NC}"
  echo -e "  $0 -d video.mov         ${BLUE}# Becomes video.mp4, original deleted${NC}"
  echo -e "  $0 video.mp4 ./out/     ${BLUE}# Saves to ./out/video.mp4${NC}"
  exit 1
}

# --- Parse Arguments ---
while getopts "msrdh" opt; do
  case ${opt} in
    m) COMPRESSION_MODE="maximum" ;;
    s) COMPRESSION_MODE="standard" ;;
    r) REPLACE=true ;;
    d) DELETE_ORIGINAL=true ;;
    h) usage ;;
    \?) echo -e "${RED}Invalid option: -$OPTARG${NC}" 1>&2; usage ;;
  esac
done
shift $((OPTIND - 1))

INPUT_FILE="$1"
OUTPUT_FOLDER="$2"

# --- Input Validation ---
if [ -z "$INPUT_FILE" ]; then
  echo -e "${RED}${ICON_ERROR} Error: No input file specified.${NC}"
  usage
fi

if [ ! -f "$INPUT_FILE" ]; then
  echo -e "${RED}${ICON_ERROR} Error: File '$INPUT_FILE' not found.${NC}"
  exit 1
fi

# --- Path and Filename Logic ---
DIRNAME=$(dirname "$INPUT_FILE")
BASENAME=$(basename "$INPUT_FILE")
FILENAME="${BASENAME%.*}"
# We prefer .mp4 for the output container (x264/aac)
OUTPUT_EXT="mp4"

# Logic for Output Filename
if [ -n "$OUTPUT_FOLDER" ]; then
  # If output folder is specified, use it
  mkdir -p "$OUTPUT_FOLDER"
  OUTPUT_FOLDER=${OUTPUT_FOLDER%/}
  OUTPUT_FILE="${OUTPUT_FOLDER}/${FILENAME}.${OUTPUT_EXT}"
else
  # No output folder specified
  if [ "$REPLACE" = true ]; then
    # Replace mode: overwrite input file (keep original extension if not careful, but usually implies same file)
    OUTPUT_FILE="$INPUT_FILE"
  elif [ "$DELETE_ORIGINAL" = true ]; then
    # Delete mode: Same dir, new extension
    OUTPUT_FILE="${DIRNAME}/${FILENAME}.${OUTPUT_EXT}"
  else
    # Default mode: Same dir, suffix added
    OUTPUT_FILE="${DIRNAME}/${FILENAME}_compressed.${OUTPUT_EXT}"
  fi
fi

# --- OS Detection & Optimization ---
OS_TYPE=$(uname -s)
NICE_CMD=""
case "$OS_TYPE" in
  Darwin*|Linux*) NICE_CMD="nice -n 10" ;;
  *) NICE_CMD="" ;;
esac

# --- Analyze Source File ---
echo -e "${BLUE}${ICON_INFO} Analyzing source file...${NC}"

# Get file size
ORIG_SIZE=$(wc -c <"$INPUT_FILE")

# Get Video Info (Width, Height, Codec) - Efficient single call
VIDEO_INFO=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height,codec_name -of csv=p=0 "$INPUT_FILE")
# Parse CSV: width,height,codec
IFS=',' read -r ORIG_WIDTH ORIG_HEIGHT ORIG_CODEC <<< "$VIDEO_INFO"

# Fallback if ffprobe fails to get data
if [ -z "$ORIG_WIDTH" ]; then ORIG_WIDTH="N/A"; fi
if [ -z "$ORIG_HEIGHT" ]; then ORIG_HEIGHT="N/A"; fi
if [ -z "$ORIG_CODEC" ]; then ORIG_CODEC="N/A"; fi

human_filesize() {
  awk -v sum="$1" ' BEGIN {hum[1024^3]="GB"; hum[1024^2]="MB"; hum[1024]="KB"; for (x=1024^3; x>=1024; x/=1024) { if (sum>=x) { printf "%.2f %s\n", sum/x, hum[x]; break } } }'
}
ORIG_SIZE_HR=$(human_filesize $ORIG_SIZE)

# --- Define Compression Parameters ---
if [ "$COMPRESSION_MODE" == "maximum" ]; then
  MODE_LABEL="MAXIMUM (Max 720p, Mono)"
  MODE_COLOR="${PURPLE}"
  # Max 720p (width 1280). 
  FFMPEG_ARGS=(
    -c:v libx264 -preset veryslow -crf 28
    -vf "scale='min(1280,iw)':-2"
    -c:a aac -b:a 64k -ac 1
    -movflags +faststart
  )
else
  MODE_LABEL="STANDARD (Max 1080p, Stereo)"
  MODE_COLOR="${GREEN}"
  FFMPEG_ARGS=(
    -c:v libx264 -preset slower -crf 26
    -vf "scale='min(1920,iw)':-2"
    -c:a aac -b:a 128k -ac 2
    -movflags +faststart
  )
fi

# --- Show Start Info ---
echo -e "${WHITE}==================================================${NC}"
echo -e "  ${ICON_VIDEO}  ${BOLD}VIDEO COMPRESSION JOB${NC}"
echo -e "${WHITE}==================================================${NC}"
echo -e "${BOLD}Input:${NC}         ${INPUT_FILE}"
echo -e "${BOLD}Details:${NC}       ${ORIG_WIDTH}x${ORIG_HEIGHT} | ${ORIG_CODEC} | ${ORIG_SIZE_HR}"
echo -e "${BOLD}Mode:${NC}          ${MODE_COLOR}${MODE_LABEL}${NC}"
echo -e "${BOLD}Output:${NC}        ${OUTPUT_FILE}"
if [ "$DELETE_ORIGINAL" = true ]; then
  echo -e "${BOLD}Action:${NC}        ${RED}${ICON_TRASH} Original will be DELETED after success${NC}"
fi
echo -e "${WHITE}==================================================${NC}"
echo -e "${CYAN}${ICON_INFO} Processing...${NC}"

# --- Execute FFmpeg ---
# Use .mp4 temp file to ensure mp4 container is used
TEMP_FILE="${OUTPUT_FILE}.tmp.mp4"

# Trap Ctrl+C to clean up
trap 'rm -f "$TEMP_FILE"; echo -e "\n${RED}${ICON_ERROR} Aborted by user.${NC}"; exit 1' SIGINT

# Run FFmpeg
$NICE_CMD ffmpeg -v error -stats -i "$INPUT_FILE" "${FFMPEG_ARGS[@]}" -y "$TEMP_FILE"
STATUS=$?

echo "" # New line after stats

if [ $STATUS -eq 0 ]; then
  # Move temp file to final destination
  mv "$TEMP_FILE" "$OUTPUT_FILE"

  # --- Summarize ---
  NEW_SIZE=$(wc -c <"$OUTPUT_FILE")
  NEW_SIZE_HR=$(human_filesize $NEW_SIZE)

  # Calculate stats
  if [ $ORIG_SIZE -gt 0 ]; then
    SAVED_BYTES=$((ORIG_SIZE - NEW_SIZE))
    if [ $SAVED_BYTES -lt 0 ]; then
      PERCENT_SAVED="0.0" 
      SAVED_COLOR="${RED}"
    else
      PERCENT_SAVED=$(awk "BEGIN {printf \"%.1f\", ($SAVED_BYTES / $ORIG_SIZE) * 100}")
      SAVED_COLOR="${GREEN}"
    fi
  else
    PERCENT_SAVED=0
    SAVED_COLOR="${NC}"
  fi

  echo -e "${WHITE}==================================================${NC}"
  echo -e "  ${ICON_SUCCESS}  ${BOLD}${GREEN}COMPRESSION COMPLETE${NC}"
  echo -e "${WHITE}==================================================${NC}"
  echo -e "${BOLD}Original:${NC}      ${ORIG_SIZE_HR}"
  echo -e "${BOLD}New Size:${NC}      ${GREEN}${NEW_SIZE_HR}${NC}"
  echo -e "${BOLD}Reduction:${NC}     ${SAVED_COLOR}-${PERCENT_SAVED}%${NC}"
  echo -e "${BOLD}Location:${NC}      ${ICON_SAVE} ${OUTPUT_FILE}"

  # Handle Delete Mode
  if [ "$DELETE_ORIGINAL" = true ]; then
    if [ "$INPUT_FILE" != "$OUTPUT_FILE" ]; then
      rm "$INPUT_FILE"
      echo -e "${BOLD}Status:${NC}        ${RED}${ICON_TRASH} Original file deleted.${NC}"
    else
      # Input and Output were the same file (e.g. input.mp4 -> input.mp4), so it was overwritten
      echo -e "${BOLD}Status:${NC}        ${YELLOW}File replaced (In-place).${NC}"
    fi
  fi
  echo -e "${WHITE}==================================================${NC}"

else
  echo -e "${RED}${ICON_ERROR} Compression failed!${NC}"
  rm -f "$TEMP_FILE"
  exit 1
fi
