#!/usr/bin/env fish

function show_help
    echo "Usage: watch-torrent [MAGNET_LINK|TORRENT_FILE]"
    echo ""
    echo "Streams a torrent directly to mpv using webtorrent-cli"
    echo ""
    echo "Arguments:"
    echo "  MAGNET_LINK    Magnet link starting with 'magnet:?'"
    echo "  TORRENT_FILE   Path to a .torrent file"
    exit 1
end

# Show help if no arguments or help flags
if test (count $argv) -ne 1; or contains -- "$argv[1]" "--help" "-help" "-h"
    show_help
end

# Stream using webtorrent to mpv
webtorrent "$argv[1]" --mpv
