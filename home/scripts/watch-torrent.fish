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
if test (count $argv) -ne 1; or contains -- "$argv[1]" --help -help -h
    show_help
end

# Get the user's mpv config directory
set mpv_config_dir "$HOME/.config/mpv"

# Stream using webtorrent to mpv with explicit config directory
webtorrent "$argv[1]" --not-on-top --mpv --player-args="--config-dir=$mpv_config_dir"
