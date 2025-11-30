#!/bin/bash

CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
PORT=9222
PROFILE_DIR="/tmp/chrome-ai"

# Kill only Chrome processes running in debug mode
echo "Stopping previous debug Chrome..."
ps aux | grep "$CHROME" | grep "remote-debugging-port" | awk '{print $2}' | xargs kill -9 2>/dev/null

# Start debugging Chrome
echo "Starting Chrome in remote debugging mode on port $PORT..."
"$CHROME" \
  --remote-debugging-port=$PORT \
  --user-data-dir="$PROFILE_DIR"
