#!/usr/bin/env bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 <filename>"
    exit 1
fi

filename="$1"

while true; do
    sleep 1
    echo "$(pbpaste)" >> "$filename"
done