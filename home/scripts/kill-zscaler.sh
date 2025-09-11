#!/usr/bin/env bash
set -e

echo "Unloading Zscaler services..."

# Unload user agents (no sudo needed)
if [ -d "/Library/LaunchAgents" ]; then
    find /Library/LaunchAgents -name '*zscaler*' -type f 2>/dev/null | while read -r plist; do
        if [ -f "$plist" ]; then
            echo "Unloading user agent: $plist"
            launchctl unload "$plist" 2>/dev/null || true
        fi
    done
fi

# Unload system daemons (requires sudo)
if [ -d "/Library/LaunchDaemons" ]; then
    sudo find /Library/LaunchDaemons -name '*zscaler*' -type f 2>/dev/null | while read -r plist; do
        if [ -f "$plist" ]; then
            echo "Unloading system daemon: $plist"
            sudo launchctl unload "$plist" 2>/dev/null || true
        fi
    done
fi

echo "Done unloading Zscaler services."