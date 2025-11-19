#!/usr/bin/env bash

MOS_APP_PATH="$HOME/Applications/Home Manager Apps/Mos.app"

# Open System Settings to Trackpad settings (opens on Point & Click tab)
open "x-apple.systempreferences:com.apple.preference.trackpad"

echo "Opened System Settings > Trackpad"
echo "Manually switch to 'Scroll & Zoom' tab and toggle 'Natural scrolling'"

# Toggle Mos app
if pgrep -f "Mos" >/dev/null; then
  # Mos is running, quit it
  osascript -e 'tell application "Mos" to quit' 2>/dev/null
  echo "Asked Mos app to quit"
else
  # Mos is not running, start it
  if [[ -d "$MOS_APP_PATH" ]]; then
    open "$MOS_APP_PATH"
    echo "Started Mos app"
  else
    echo "Warning: Mos app not found at $MOS_APP_PATH"
  fi
fi
