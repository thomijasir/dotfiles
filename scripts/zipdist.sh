#!/bin/bash

# Get current directory name (parent folder)
PARENT_DIR=$(basename "$(pwd)")

# Check if 'dist' folder exists
if [ ! -d "dist" ]; then
  echo "Error: 'dist' folder not found in current directory."
  exit 1
fi

# Generate timestamp in format YYYYMMDD_HHMMSS
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Create zip file name: parentName_timestamp.zip
ZIP_NAME="${PARENT_DIR}_${TIMESTAMP}.zip"

# Zip the 'dist' folder
zip -r "$ZIP_NAME" dist

# delete folder
rm -rf dist

echo "✅ Successfully created: $ZIP_NAME"
