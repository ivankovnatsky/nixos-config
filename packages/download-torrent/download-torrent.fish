#!/usr/bin/env fish

function show_help
    echo "Usage: download-torrent [MAGNET_LINK|TORRENT_FILE...]"
    echo ""
    echo "Downloads torrents using aria2c from magnet links or torrent files"
    echo "Default download location: current directory"
    echo ""
    echo "Arguments:"
    echo "  MAGNET_LINK    Magnet link starting with 'magnet:?'"
    echo "  TORRENT_FILE   Path to a .torrent file (supports multiple files/globs)"
    exit 1
end

# Show help if no arguments or help flags
if test (count $argv) -lt 1; or contains -- "$argv[1]" --help -help -h
    show_help
end

# Set default download directory to current $PWD
set download_dir .

# Download all arguments using aria2c (parallel)
aria2c --dir $download_dir $argv
