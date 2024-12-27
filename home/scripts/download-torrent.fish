#!/usr/bin/env fish

function show_help
    echo "Usage: download-torrent [MAGNET_LINK|TORRENT_FILE]"
    echo ""
    echo "Downloads a torrent using aria2c from either a magnet link or torrent file"
    echo ""
    echo "Arguments:"
    echo "  MAGNET_LINK    Magnet link starting with 'magnet:?'"
    echo "  TORRENT_FILE   Path to a .torrent file"
    exit 1
end

# Show help if no arguments or --help
if test (count $argv) -ne 1; or test "$argv[1]" = "--help"
    show_help
end

# Download using aria2c to current directory
aria2c --dir ./ "$argv[1]"
