#!/usr/bin/env sh

# Script to remotely unlock and connect to homelab machines
# Usage: ./poweron-homelab.sh
# This script will unlock Mini and optionally open Screen Sharing

set -e

MINI_IP="192.168.50.4"
MINI_USER="ivan"

echo "Attempting to unlock Mini at $MINI_IP..."

# Unlock via SSH - prompts for password
ssh -o ConnectTimeout=10 "${MINI_USER}@${MINI_IP}" "echo 'System unlocked'"

echo "Mini should now be unlocked."

# Ask if user wants to open Screen Sharing
printf "Open Screen Sharing? [y/N] "
read -r response
case "$response" in
    [yY]|[yY][eE][sS])
        # Use osascript to connect without creating duplicate entries
        # This activates Screen Sharing and connects to existing or creates new connection
        osascript -e "
            tell application \"Screen Sharing\"
                activate
                open location \"vnc://${MINI_USER}@${MINI_IP}\"
            end tell
        "
        ;;
    *)
        echo "Skipping Screen Sharing."
        ;;
esac

# Wait for user to unlock via UI, then set DNS
printf "Press Enter after unlocking Mini via Screen Sharing... "
read -r
dns "$MINI_IP"
