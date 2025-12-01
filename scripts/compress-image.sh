#!/bin/bash

# scripts/compress-image.sh

# Function to check dependencies
check_dependencies() {
    local missing=0
    
    if ! command -v magick &> /dev/null && ! command -v convert &> /dev/null; then
        echo "Error: ImageMagick is missing. Please install it (e.g., brew install imagemagick)."
        missing=1
    fi
    
    if ! command -v pngquant &> /dev/null; then
        echo "Error: pngquant is missing. Please install it (e.g., brew install pngquant)."
        missing=1
    fi
    
    # Check for mozjpeg (usually installed as cjpeg)
    if ! command -v cjpeg &> /dev/null && ! command -v mozjpeg &> /dev/null; then
        echo "Error: mozjpeg is missing. Please install it (e.g., brew install mozjpeg)."
        missing=1
    fi
    
    if [ $missing -eq 1 ]; then
        exit 1
    fi
}

# Function to show usage
usage() {
    echo "Usage: $(basename "$0") [-s] [-r] <input_file> [output_folder]"
    echo ""
    echo "Options:"
    echo "  -s    Use standard compression (default: maximum compression)"
    echo "  -r    Replace the original file"
    echo ""
    echo "Arguments:"
    echo "  <input_file>     Path to the image file (jpg, jpeg, png)"
    echo "  [output_folder]  Directory to save the output file (optional)"
    exit 1
}

# Default settings
MODE="maximum"
REPLACE=false

# Parse flags
while getopts ":sr" opt; do
  case ${opt} in
    s)
      MODE="standard"
      ;;
    r)
      REPLACE=true
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      usage
      ;;
  esac
done
shift $((OPTIND -1))

INPUT_FILE="$1"
OUTPUT_FOLDER="$2"

# Validate input
if [ -z "$INPUT_FILE" ]; then
    echo "Error: Input file is required."
    usage
fi

if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: File '$INPUT_FILE' not found."
    exit 1
fi

# Check dependencies
check_dependencies

# Determine commands
if command -v magick &> /dev/null; then
    IM_CMD="magick"
else
    IM_CMD="convert"
fi

if command -v cjpeg &> /dev/null; then
    JPEG_CMD="cjpeg"
else
    JPEG_CMD="mozjpeg"
fi

# Check file extension
FILENAME=$(basename "$INPUT_FILE")
EXT="${FILENAME##*.}"
EXT_LOWER=$(echo "$EXT" | tr '[:upper:]' '[:lower:]')

if [[ "$EXT_LOWER" != "jpg" && "$EXT_LOWER" != "jpeg" && "$EXT_LOWER" != "png" ]]; then
    echo "Error: Unsupported file format '.$EXT'. Only jpg, jpeg, and png are supported."
    exit 1
fi

# Set compression parameters
if [ "$MODE" == "maximum" ]; then
    # Maximum compression (lowest file size, viewable)
    # Max resolution: Full HD (1920x1080)
    MAX_WIDTH=1920
    MAX_HEIGHT=1080
    PNG_QUALITY="40-60"
    JPG_QUALITY="50"
else
    # Standard compression (better quality)
    # Max resolution: 4K (3840x2160)
    MAX_WIDTH=3840
    MAX_HEIGHT=2160
    PNG_QUALITY="80-95"
    JPG_QUALITY="85"
fi

# Determine output path
DIRNAME=$(dirname "$INPUT_FILE")

if [ "$REPLACE" = true ]; then
    OUTPUT_FILE="$INPUT_FILE"
else
    if [ -n "$OUTPUT_FOLDER" ]; then
        # Create output folder if it doesn't exist
        mkdir -p "$OUTPUT_FOLDER"
        OUTPUT_FILE="${OUTPUT_FOLDER}/${FILENAME}"
    else
        OUTPUT_FILE="${DIRNAME}/${FILENAME%.*}_compressed.${EXT}"
    fi
fi

echo "Starting compression..."
echo "File: $INPUT_FILE"
echo "Mode: $MODE"
echo "Max Resolution: ${MAX_WIDTH}x${MAX_HEIGHT}"
echo "Output: $OUTPUT_FILE"

# Create a temporary file
TEMP_FILE=$(mktemp)

# Process image
# -resize 'WxH>' resizes only if the image is larger than the dimensions
if [[ "$EXT_LOWER" == "png" ]]; then
    # Resize with ImageMagick, output to stdout as PNG, pipe to pngquant
    # pngquant: --speed 1 (slowest, best compression)
    $IM_CMD "$INPUT_FILE" -resize "${MAX_WIDTH}x${MAX_HEIGHT}>" png:- | pngquant --quality "$PNG_QUALITY" --speed 1 - > "$TEMP_FILE"
else
    # JPG/JPEG
    # Resize with ImageMagick, output to stdout as PPM (lossless raw), pipe to mozjpeg
    $IM_CMD "$INPUT_FILE" -resize "${MAX_WIDTH}x${MAX_HEIGHT}>" ppm:- | $JPEG_CMD -quality "$JPG_QUALITY" > "$TEMP_FILE"
fi

# Check result
if [ $? -eq 0 ] && [ -s "$TEMP_FILE" ]; then
    mv "$TEMP_FILE" "$OUTPUT_FILE"
    echo "Compression successful."
    
    # Show stats
    ORIG_SIZE=$(du -h "$INPUT_FILE" | awk '{print $1}')
    NEW_SIZE=$(du -h "$OUTPUT_FILE" | awk '{print $1}')
    echo "Original size: $ORIG_SIZE"
    echo "New size:      $NEW_SIZE"
else
    echo "Error: Compression failed."
    rm -f "$TEMP_FILE"
    exit 1
fi
