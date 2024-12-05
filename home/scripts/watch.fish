#!/usr/bin/env fish

# Default interval in seconds
set default_interval 5

# Check if we have the required arguments
if test (count $argv) -lt 1
    echo "Usage: watch.sh \"COMMAND\" [SECONDS]"
    echo "Example: watch.sh \"ls -la\" 2"
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
    echo "----------------------------------------"
    echo "Every $interval seconds: $command"
    echo "Press Ctrl+C to exit"
    echo "Last updated: "(date)
    echo ""
    
    # Execute the command
    eval $command
    
    # Wait for specified interval
    sleep $interval
end
