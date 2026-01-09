#!/usr/bin/env bash
# Get contents of a Terminal.app window

set -euo pipefail

list_windows() {
    osascript -e '
tell application "Terminal"
    set windowCount to count of windows
    repeat with i from 1 to windowCount
        try
            set tabCount to count of tabs of window i
            repeat with j from 1 to tabCount
                try
                    set tabProcesses to processes of tab j of window i
                    set lastProcess to last item of tabProcesses
                    log "Window " & i & ", Tab " & j & ": " & lastProcess
                on error
                    log "Window " & i & ", Tab " & j & ": (unknown)"
                end try
            end repeat
        on error
            log "Window " & i & ": (inaccessible)"
        end try
    end repeat
end tell
' 2>&1 | grep -v "execution error" || true
}

show_help() {
    cat << EOF
Usage: tail-terminal.sh [OPTIONS]

Get contents of a Terminal.app window

Options:
  -l, --lines N     Number of lines to show (default: 20)
  -w, --window N    Window number or "front" (default: front)
  --list            List all Terminal windows and tabs
  -h, --help        Show this help message

Note: Windows are numbered by focus order (most recent = 1), not visual position.

Examples:
  tail-terminal.sh                    # 20 lines from front window
  tail-terminal.sh --lines 50         # 50 lines from front window
  tail-terminal.sh -l 10 -w 2         # 10 lines from window 2
  tail-terminal.sh --list             # List all windows and tabs
EOF
    exit 0
}

lines=20
window="front"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -l|--lines)
            lines="$2"
            shift 2
            ;;
        -w|--window)
            window="$2"
            shift 2
            ;;
        --list)
            list_windows
            exit 0
            ;;
        -h|--help)
            show_help
            ;;
        *)
            echo "Unknown option: $1" >&2
            echo "Use --help for usage information" >&2
            exit 1
            ;;
    esac
done

if [[ "$window" == "front" ]]; then
    window_selector="front window"
else
    window_selector="window $window"
fi

osascript -e "tell application \"Terminal\" to get contents of selected tab of $window_selector" | tail -"$lines"
