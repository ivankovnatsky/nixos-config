#!/usr/bin/env bash

set -euo pipefail

SPACES_PLIST=~/Library/Preferences/com.apple.spaces.plist

usage() {
  echo "Usage: $(basename "$0") <add|remove>"
  echo "  add    - Add a new desktop space"
  echo "  remove - Remove the current desktop space"
  exit 1
}

get_current_space_index() {
  plutil -convert json -o - "$SPACES_PLIST" | jq -r '
    .SpacesDisplayConfiguration."Management Data".Monitors[]
    | select(has("Current Space"))
    | ."Current Space".ManagedSpaceID as $current
    | [.Spaces[] | select(.type == 0) | .ManagedSpaceID]
    | to_entries
    | .[]
    | select(.value == $current)
    | .key + 1
  '
}

add_space() {
  osascript -e '
tell application "Mission Control" to launch
delay 0.7
tell application "System Events"
  tell group "Spaces Bar" of group 1 of group "Mission Control" of process "Dock"
    click button 1
  end tell
end tell
'
}

remove_space() {
  local index
  index=$(get_current_space_index)

  if [[ -z "$index" ]]; then
    echo "Error: Could not determine current space index" >&2
    exit 1
  fi

  osascript -e "
tell application \"Mission Control\" to launch
delay 0.7
tell application \"System Events\"
  tell list 1 of group \"Spaces Bar\" of group 1 of group \"Mission Control\" of process \"Dock\"
    perform action \"AXRemoveDesktop\" of button $index
  end tell
end tell
"
}

[[ $# -lt 1 ]] && usage

case "$1" in
  add)
    add_space
    ;;
  remove)
    remove_space
    ;;
  *)
    usage
    ;;
esac
