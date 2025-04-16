#!/usr/bin/env bash
#
# video-to-bookshelf.sh - Download a YouTube video, extract audio, and upload to Audiobookshelf
#
# This script combines the functionality of video-to-audio.sh and audiobookshelf.py

set -e

# Default values
VIDEO_URL=""
ABS_URL="${ABS_URL:-}"

# Parse arguments
usage() {
    echo "Usage: $0 --video-url <YouTube_URL> [--abs-url <Audiobookshelf_URL>]"
    echo
    echo "Options:"
    echo "  --video-url   YouTube video URL to download and convert"
    echo "  --abs-url     Audiobookshelf server URL (optional, can use ABS_URL env var)"
    echo
    exit 1
}

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --video-url) VIDEO_URL="$2"; shift ;;
        --abs-url) ABS_URL="$2"; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown parameter: $1"; usage ;;
    esac
    shift
done

# Check if required arguments are provided
if [ -z "$VIDEO_URL" ]; then
    echo "Error: YouTube URL is required"
    usage
fi

echo "Video URL: $VIDEO_URL"
if [ -n "$ABS_URL" ]; then
    echo "Audiobookshelf URL: $ABS_URL"
else
    echo "Using default Audiobookshelf URL"
fi

# Create a unique temporary directory
TEMP_DIR=$(mktemp -d -t video-to-bookshelf-XXXXXXXX)
echo "Created temporary directory: $TEMP_DIR"

# Change to the temporary directory
cd "$TEMP_DIR"

echo "Downloading and extracting audio from $VIDEO_URL..."
# Use the video-to-audio script
video-to-audio "$VIDEO_URL"

# Find the generated MP3 file
MP3_FILE=$(find . -name "*.mp3" | head -n 1)

if [ -z "$MP3_FILE" ]; then
    echo "Error: No MP3 file was generated."
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Get the absolute path
MP3_FILE_PATH="$TEMP_DIR/$MP3_FILE"
MP3_FILE_PATH=${MP3_FILE_PATH#./}  # Remove leading ./ if present

echo "Audio extraction completed. File: $MP3_FILE_PATH"

# Upload to Audiobookshelf
echo "Uploading to Audiobookshelf..."
if [ -n "$ABS_URL" ]; then
    audiobookshelf upload --url "$ABS_URL" --file "$MP3_FILE_PATH"
else
    audiobookshelf upload --file "$MP3_FILE_PATH"
fi

# Clean up
echo "Cleaning up temporary directory..."
rm -rf "$TEMP_DIR"

echo "Process completed successfully!"
