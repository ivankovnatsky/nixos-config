#!/usr/bin/env bash
# Get contents of a Terminal.app window

set -euo pipefail

show_help() {
    cat << EOF
Usage: tail-terminal.sh [OPTIONS]

Get contents of a Terminal.app window

Options:
  -l, --lines N     Number of lines to show (default: 20)
  -w, --window N    Window number or "front" (default: front)
  -h, --help        Show this help message

Note: Windows are numbered by focus order (most recent = 1), not visual position.

Examples:
  tail-terminal.sh                    # 20 lines from front window
  tail-terminal.sh --lines 50         # 50 lines from front window
  tail-terminal.sh -l 10 -w 2         # 10 lines from window 2
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
