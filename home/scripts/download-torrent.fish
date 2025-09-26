#!/usr/bin/env fish

function show_help
    echo "Usage: download-torrent [MAGNET_LINK|TORRENT_FILE]"
    echo ""
    echo "Downloads a torrent using aria2c from either a magnet link or torrent file"
    echo "Default download location: ~/Downloads"
    echo ""
    echo "Arguments:"
    echo "  MAGNET_LINK    Magnet link starting with 'magnet:?'"
    echo "  TORRENT_FILE   Path to a .torrent file"
    exit 1
end

# Show help if no arguments or help flags
if test (count $argv) -ne 1; or contains -- "$argv[1]" --help -help -h
    show_help
end

# Set default download directory to current $PWD
set download_dir .

# Download using aria2c to the specified download directory
aria2c --dir $download_dir "$argv[1]"
