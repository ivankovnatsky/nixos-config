#!/usr/bin/env bash

set -euo pipefail

usage() {
  echo "Download YouTube playlist items in parallel"
  echo ""
  echo "Usage: $(basename "$0") [OPTIONS] <URL>"
  echo ""
  echo "Options:"
  echo "  -j, --jobs N       Number of parallel downloads (default: 4)"
  echo "  -o, --output DIR   Output directory (default: current directory)"
  echo "  -f, --format FMT   yt-dlp format string (default: bestvideo[height<=1080]+bestaudio/best)"
  echo "  -h, --help         Show this help message"
  echo ""
  echo "Examples:"
  echo "  $(basename "$0") 'https://www.youtube.com/playlist?list=PLxxxxx'"
  echo "  $(basename "$0") -j 8 -o ~/Videos 'https://www.youtube.com/playlist?list=PLxxxxx'"
  exit 0
}

JOBS=4
OUTPUT_DIR="."
FORMAT="bestvideo[height<=1080]+bestaudio/best"
URL=""

while [[ $# -gt 0 ]]; do
  case "$1" in
  -j | --jobs)
    JOBS="$2"
    shift 2
    ;;
  -o | --output)
    OUTPUT_DIR="$2"
    shift 2
    ;;
  -f | --format)
    FORMAT="$2"
    shift 2
    ;;
  -h | --help)
    usage
    ;;
  -*)
    echo "Unknown option: $1"
    usage
    ;;
  *)
    URL="$1"
    shift
    ;;
  esac
done

if [[ -z "$URL" ]]; then
  echo "Error: URL is required"
  usage
fi

mkdir -p "$OUTPUT_DIR"

echo "Fetching playlist items..."
VIDEO_URLS=$(yt-dlp --flat-playlist --print url "$URL" 2>/dev/null)

if [[ -z "$VIDEO_URLS" ]]; then
  echo "No videos found in playlist or invalid URL"
  exit 1
fi

VIDEO_COUNT=$(echo "$VIDEO_URLS" | wc -l | tr -d ' ')
echo "Found $VIDEO_COUNT videos, downloading with $JOBS parallel jobs..."

echo "$VIDEO_URLS" | xargs -P "$JOBS" -I {} yt-dlp \
  --format "$FORMAT" \
  --merge-output-format mp4 \
  --write-auto-subs \
  --embed-subs \
  --sub-langs en \
  --ignore-errors \
  -o "$OUTPUT_DIR/%(title)s.%(ext)s" \
  {}

echo "Download complete!"
