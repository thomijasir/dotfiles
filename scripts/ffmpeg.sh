#!/bin/bash

# Video Compression Script for Web Optimization
# Usage: ./ffmpeg.sh input_video.mov

set -e

# Check if input file is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <input_video>"
  echo "Example: $0 myvideo/video.mov"
  exit 1
fi

INPUT="$1"

# Check if file exists
if [ ! -f "$INPUT" ]; then
  echo "Error: File '$INPUT' not found!"
  exit 1
fi

# Check if ffmpeg is installed
if ! command -v ffmpeg &>/dev/null; then
  echo "Error: ffmpeg is not installed. Please install it first."
  exit 1
fi

# Extract directory, filename, and extension
DIR=$(dirname "$INPUT")
FILENAME=$(basename "$INPUT")
NAME="${FILENAME%.*}"
OUTPUT="${DIR}/${NAME}_compress.mp4"

echo "================================================"
echo "Video Compression Tool"
echo "================================================"
echo "Input:  $INPUT"
echo "Output: $OUTPUT"
echo "================================================"

# Get video information
echo "Analyzing video..."
VIDEO_CODEC=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$INPUT")
WIDTH=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of default=noprint_wrappers=1:nokey=1 "$INPUT")
HEIGHT=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of default=noprint_wrappers=1:nokey=1 "$INPUT")
FPS=$(ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of default=noprint_wrappers=1:nokey=1 "$INPUT" | bc -l)
DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$INPUT")

echo "Original codec: $VIDEO_CODEC"
echo "Resolution: ${WIDTH}x${HEIGHT}"
echo "Frame rate: ${FPS} fps"
echo "Duration: ${DURATION}s"
echo "================================================"

# Determine optimal settings based on resolution
if [ "$WIDTH" -gt 1920 ] || [ "$HEIGHT" -gt 1080 ]; then
  # 4K or higher - scale down to 1080p
  SCALE="scale=1920:-2"
  CRF=23
  echo "Resolution: Scaling down to 1080p for web optimization"
elif [ "$WIDTH" -gt 1280 ] || [ "$HEIGHT" -gt 720 ]; then
  # 1080p - keep resolution
  SCALE=""
  CRF=23
  echo "Resolution: Keeping 1080p"
else
  # 720p or lower - keep resolution
  SCALE=""
  CRF=28
  echo "Resolution: Keeping original (720p or lower)"
fi

# Set frame rate cap for web (max 30fps for smaller files)
if [ $(echo "$FPS > 30" | bc -l) -eq 1 ]; then
  FPS_FILTER="-r 30"
  echo "Frame rate: Capping at 30fps"
else
  FPS_FILTER=""
  echo "Frame rate: Keeping original"
fi

echo "================================================"
echo "Starting compression..."
echo "Using H.264 codec with CRF=$CRF"
echo "================================================"

# Build ffmpeg command with optimal settings for web
FFMPEG_CMD="ffmpeg -i \"$INPUT\" -c:v libx264 -preset slow -crf $CRF"

# Add scaling if needed
if [ -n "$SCALE" ]; then
  FFMPEG_CMD="$FFMPEG_CMD -vf $SCALE"
fi

# Add frame rate filter if needed
if [ -n "$FPS_FILTER" ]; then
  FFMPEG_CMD="$FFMPEG_CMD $FPS_FILTER"
fi

# Add audio settings and other optimizations
FFMPEG_CMD="$FFMPEG_CMD -c:a aac -b:a 128k -ac 2 -movflags +faststart -pix_fmt yuv420p \"$OUTPUT\" -y"

# Execute compression
eval $FFMPEG_CMD

# Check if compression was successful
if [ $? -eq 0 ]; then
  echo "================================================"
  echo "Compression completed successfully!"
  echo "================================================"

  # Show file sizes
  ORIGINAL_SIZE=$(du -h "$INPUT" | cut -f1)
  COMPRESSED_SIZE=$(du -h "$OUTPUT" | cut -f1)

  echo "Original size:   $ORIGINAL_SIZE"
  echo "Compressed size: $COMPRESSED_SIZE"
  echo "Output file:     $OUTPUT"
  echo "================================================"
else
  echo "Error: Compression failed!"
  exit 1
fi
