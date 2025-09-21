#!/usr/bin/env bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 <filename>"
    exit 1
fi

filename="$1"

while true; do
    sleep 1
    paste_content="$(pbpaste)"
    if ! grep -Fxq "$paste_content" "$filename" 2>/dev/null; then
        echo "$paste_content" >> "$filename"
    fi
done