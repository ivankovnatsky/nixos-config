#!/usr/bin/env bash

# The purpose of this script is to only exclude directories to which user does
# not have access in macOS.

set -euo pipefail

cd $HOME/../ || exit 1

tar \
    --exclude='**/*.sock' \
    --exclude='**/.gnupg/S.*' \
    --exclude='**/.ollama/**' \
    --exclude='**/.cache/nix/**' \
    --exclude='**/Library/Group Containers/group.com.apple.CoreSpeech/**' \
    --exclude='**/Library/Group Containers/group.com.apple.secure-control-center-preferences/**' \
    -c \
    $USER | \
    pv | \
    pigz > /tmp/$USER.tar.gz
