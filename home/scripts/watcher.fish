#!/usr/bin/env fish

# Default interval in seconds
set default_interval 5

# Function to display help
function show_help
    echo "Usage: watcher \"COMMAND\" [SECONDS]"
    echo ""
    echo "Repeatedly runs a command at specified intervals."
    echo ""
    echo "Options:"
    echo "  --help     Display this help message"
    echo ""
    echo "Arguments:"
    echo "  COMMAND    The command to execute (use quotes for commands with spaces)"
    echo "  SECONDS    Optional: Time interval between executions (default: $default_interval)"
    echo ""
    echo "Examples:"
    echo "  watcher \"ls -la\""
    echo "  watcher \"git status\" 10"
    exit 0
end

# Check for help flag
if test (count $argv) -eq 0; or test "$argv[1]" = "--help"; or test "$argv[1]" = "-h"
    show_help
end

# Check if we have the required arguments
if test (count $argv) -lt 1
    echo "Error: Missing command argument."
    echo "Run 'watcher --help' for usage information."
    exit 1
end

# Store the command and interval, using the default interval if not provided
set command $argv[1]
if test (count $argv) -ge 2
    set interval $argv[2]
else
    set interval $default_interval
end

while true
    clear
    echo "----------------------------------------"
    echo "Every $interval: $command"
    echo "Press Ctrl+C to exit"
    echo "Last updated: "(date)
    echo ""

    # Execute the command
    eval $command

    # Wait for specified interval
    sleep $interval
end
