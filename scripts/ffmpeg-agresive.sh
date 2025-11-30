#!/bin/bash

# Aggressive Video Compression Script (Clop-style)
# Maximum compression for smallest file size
# Usage: ./ffmpeg.sh input_video.mov

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if input file is provided
if [ -z "$1" ]; then
  echo -e "${RED}Usage: $0 <input_video>${NC}"
  echo "Example: $0 myvideo/video.mov"
  exit 1
fi

INPUT="$1"

# Check if file exists
if [ ! -f "$INPUT" ]; then
  echo -e "${RED}Error: File '$INPUT' not found!${NC}"
  exit 1
fi

# Check if ffmpeg is installed
if ! command -v ffmpeg &>/dev/null; then
  echo -e "${RED}Error: ffmpeg is not installed. Please install it first.${NC}"
  exit 1
fi

# Extract directory, filename, and extension
DIR=$(dirname "$INPUT")
FILENAME=$(basename "$INPUT")
NAME="${FILENAME%.*}"
OUTPUT="${DIR}/${NAME}_compress.mp4"

echo -e "${YELLOW}================================================${NC}"
echo -e "${GREEN}Aggressive Video Compression Tool (Clop-style)${NC}"
echo -e "${YELLOW}================================================${NC}"
echo "Input:  $INPUT"
echo "Output: $OUTPUT"
echo -e "${YELLOW}================================================${NC}"

# Get video information
echo "Analyzing video..."
WIDTH=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of default=noprint_wrappers=1:nokey=1 "$INPUT" 2>/dev/null)
HEIGHT=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of default=noprint_wrappers=1:nokey=1 "$INPUT" 2>/dev/null)
DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$INPUT" 2>/dev/null)
FPS=$(ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of default=noprint_wrappers=1:nokey=1 "$INPUT" 2>/dev/null | awk -F'/' '{if($2>0) print $1/$2; else print $1}')

echo "Resolution: ${WIDTH}x${HEIGHT}"
echo "Duration: ${DURATION}s"
echo "Frame rate: ${FPS} fps"
echo -e "${YELLOW}================================================${NC}"

# Determine aggressive scaling and settings
# Scale down to maximize compression
if [ "$WIDTH" -gt 1920 ] || [ "$HEIGHT" -gt 1080 ]; then
  # 4K+ -> Scale to 720p for maximum compression
  TARGET_WIDTH=1280
  TARGET_HEIGHT=720
  CRF=28
  echo -e "${GREEN}Strategy: Scaling 4K+ down to 720p for maximum compression${NC}"
elif [ "$WIDTH" -gt 1280 ] || [ "$HEIGHT" -gt 720 ]; then
  # 1080p -> Scale to 720p
  TARGET_WIDTH=1280
  TARGET_HEIGHT=720
  CRF=28
  echo -e "${GREEN}Strategy: Scaling 1080p down to 720p${NC}"
else
  # 720p or lower - keep but still compress aggressively
  TARGET_WIDTH=$WIDTH
  TARGET_HEIGHT=$HEIGHT
  CRF=32
  echo -e "${GREEN}Strategy: Keeping resolution but aggressive compression${NC}"
fi

# Cap frame rate at 24fps for smaller files (cinematic look)
TARGET_FPS=24
if (($(echo "$FPS > 24" | bc -l))); then
  echo "Frame rate: Reducing to 24fps"
else
  TARGET_FPS=$FPS
  echo "Frame rate: Keeping at ${FPS} fps"
fi

# Calculate target bitrate for two-pass encoding (very aggressive)
# Target: ~0.1 bits per pixel for aggressive compression
PIXELS=$((TARGET_WIDTH * TARGET_HEIGHT))
VIDEO_BITRATE_NUM=$((PIXELS * TARGET_FPS / 10000))
TARGET_VIDEO_BITRATE="${VIDEO_BITRATE_NUM}k" # Very low bitrate
TARGET_AUDIO_BITRATE="96k"                   # Low audio bitrate

echo "Target video bitrate: $TARGET_VIDEO_BITRATE"
echo "Target audio bitrate: $TARGET_AUDIO_BITRATE"
echo -e "${YELLOW}================================================${NC}"
echo -e "${GREEN}Starting TWO-PASS aggressive compression...${NC}"
echo -e "${YELLOW}This will take a while but produces smallest files${NC}"
echo -e "${YELLOW}================================================${NC}"

# TWO-PASS ENCODING for maximum compression efficiency

# Pass 1: Analysis
echo -e "${YELLOW}Pass 1/2: Analyzing video...${NC}"
PASS1_LOG=$(mktemp)
if ! ffmpeg -i "$INPUT" \
  -c:v libx264 \
  -preset veryslow \
  -b:v "$TARGET_VIDEO_BITRATE" \
  -vf "scale=${TARGET_WIDTH}:${TARGET_HEIGHT}:flags=lanczos" \
  -r "$TARGET_FPS" \
  -pass 1 \
  -an \
  -f mp4 \
  /dev/null \
  -y 2>&1 | tee "$PASS1_LOG" | grep -E 'frame=|time=|speed='; then

  echo -e "${RED}================================================${NC}"
  echo -e "${RED}✗ PASS 1 FAILED!${NC}"
  echo -e "${RED}================================================${NC}"
  echo -e "${YELLOW}Error details:${NC}"
  tail -n 20 "$PASS1_LOG"
  rm -f "$PASS1_LOG" ffmpeg2pass-*.log
  exit 1
fi
rm -f "$PASS1_LOG"

# Pass 2: Final encoding with aggressive settings
echo -e "${YELLOW}Pass 2/2: Creating compressed video...${NC}"
PASS2_LOG=$(mktemp)
if ! ffmpeg -i "$INPUT" \
  -c:v libx264 \
  -preset veryslow \
  -b:v "$TARGET_VIDEO_BITRATE" \
  -maxrate "$TARGET_VIDEO_BITRATE" \
  -bufsize "${VIDEO_BITRATE_NUM}k" \
  -vf "scale=${TARGET_WIDTH}:${TARGET_HEIGHT}:flags=lanczos" \
  -r "$TARGET_FPS" \
  -pass 2 \
  -c:a aac \
  -b:a "$TARGET_AUDIO_BITRATE" \
  -ac 2 \
  -ar 44100 \
  -movflags +faststart \
  -pix_fmt yuv420p \
  -crf "$CRF" \
  "$OUTPUT" \
  -y 2>&1 | tee "$PASS2_LOG" | grep -E 'frame=|time=|speed='; then

  echo -e "${RED}================================================${NC}"
  echo -e "${RED}✗ PASS 2 FAILED!${NC}"
  echo -e "${RED}================================================${NC}"
  echo -e "${YELLOW}Error details:${NC}"
  tail -n 20 "$PASS2_LOG"
  rm -f "$PASS2_LOG" ffmpeg2pass-*.log
  exit 1
fi
rm -f "$PASS2_LOG"

# Clean up pass files
rm -f ffmpeg2pass-*.log

# Check if compression was successful
if [ -f "$OUTPUT" ]; then
  echo -e "${YELLOW}================================================${NC}"
  echo -e "${GREEN}✓ Compression completed successfully!${NC}"
  echo -e "${YELLOW}================================================${NC}"

  # Show file sizes and compression ratio
  ORIGINAL_SIZE=$(stat -f%z "$INPUT" 2>/dev/null || stat -c%s "$INPUT")
  COMPRESSED_SIZE=$(stat -f%z "$OUTPUT" 2>/dev/null || stat -c%s "$OUTPUT")

  ORIGINAL_MB=$(echo "scale=2; $ORIGINAL_SIZE / 1048576" | bc)
  COMPRESSED_MB=$(echo "scale=2; $COMPRESSED_SIZE / 1048576" | bc)
  RATIO=$(echo "scale=1; 100 - ($COMPRESSED_SIZE * 100 / $ORIGINAL_SIZE)" | bc)

  echo -e "${GREEN}Original size:     ${ORIGINAL_MB} MB${NC}"
  echo -e "${GREEN}Compressed size:   ${COMPRESSED_MB} MB${NC}"
  echo -e "${GREEN}Space saved:       ${RATIO}%${NC}"
  echo -e "${GREEN}Output:            $OUTPUT${NC}"
  echo -e "${YELLOW}================================================${NC}"
else
  echo -e "${RED}================================================${NC}"
  echo -e "${RED}✗ COMPRESSION FAILED!${NC}"
  echo -e "${RED}================================================${NC}"
  echo -e "${YELLOW}Possible reasons:${NC}"
  echo "  • Input file is corrupted or unsupported format"
  echo "  • Not enough disk space"
  echo "  • Insufficient permissions to write output file"
  echo "  • ffmpeg encoding error (see details above)"
  echo -e "${YELLOW}================================================${NC}"
  echo -e "${YELLOW}Troubleshooting:${NC}"
  echo "  1. Check input file: ffprobe \"$INPUT\""
  echo "  2. Check disk space: df -h"
  echo "  3. Try with different preset: Change 'veryslow' to 'medium'"
  echo "  4. Run with full ffmpeg output (remove grep filters)"
  echo -e "${YELLOW}================================================${NC}"
  exit 1
fi
