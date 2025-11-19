#!/usr/bin/env bash

# ssh-persistent.sh
# Continuously attempts to establish an SSH connection to a host
# If the connection fails or drops, it will retry after a 1-second delay
#
# Usage: ssh-persistent.sh hostname [ssh_options]
#   hostname: The SSH host to connect to
#   ssh_options: Additional SSH options (optional)

if [ $# -lt 1 ]; then
  echo "Usage: $(basename "$0") hostname [ssh_options]"
  echo "  hostname: The SSH host to connect to"
  echo "  ssh_options: Additional SSH options (optional)"
  exit 1
fi

HOST="$1"
shift
OPTIONS=("$@")

echo "Starting persistent SSH connection to $HOST"
echo "Press Ctrl+C to exit"

while true; do
  if [ ${#OPTIONS[@]} -eq 0 ]; then
    ssh "$HOST"
  else
    # shellcheck disable=SC2029
    ssh "$HOST" "${OPTIONS[@]}"
  fi

  echo "Connection to $HOST closed. Reconnecting in 1 second..."
  sleep 1
done
