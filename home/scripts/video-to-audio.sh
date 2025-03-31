#!/usr/bin/env bash

# Check if a URL is provided
if [ $# -eq 0 ]; then
    echo "Please provide a YouTube URL as an argument."
    echo "Usage: $0 <YouTube_URL>"
    exit 1
fi

# YouTube URL
URL="$1"

# Download and extract audio
yt-dlp --extract-audio --audio-format mp3 --postprocessor-args '-ac 1 -ar 24000' "$URL"

echo "Audio extraction completed."
