#!/usr/bin/env bash
# Get contents of the selected tab in Terminal.app front window

lines="${1:-20}"

osascript -e 'tell application "Terminal" to get contents of selected tab of front window' | tail -"$lines"
