#!/usr/bin/env bash

# The purpose of this script is to only exclude directories to which user does
# not have access in macOS.

set -euo pipefail

cd $HOME/../ || exit 1

# Get size estimate with dust in bytes, removing 'B' suffix
TOTAL_SIZE=$(dust -r -b -o b $HOME 2>/dev/null | head -1 | awk '{print $1}' | sed 's/B$//')

tar \
    --exclude='**/*.sock' \
    --exclude='**/*.socket' \
    --exclude='**/.gnupg/S.*' \
    --exclude='**/.ollama/**' \
    --exclude='**/.cache/nix/**' \
    --exclude='**/Library/Group Containers/group.com.apple.CoreSpeech/**' \
    --exclude='**/Library/Group Containers/group.com.apple.secure-control-center-preferences/**' \
    --no-xattrs \
    -c \
    $USER | \
    pv -s $TOTAL_SIZE -petrb | \
    pigz > /tmp/$USER.tar.gz
