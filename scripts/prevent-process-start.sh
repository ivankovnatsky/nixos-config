#!/usr/bin/env bash

if [ -z "$1" ]; then
  echo "Usage: $0 <process_name>"
  echo "Example: $0 kandji"
  exit 1
fi

PROCESS_NAME="$1"

while true; do
  pgrep -i "$PROCESS_NAME" | grep ^[0-9] | xargs -I {} sudo kill -9 {}
  sleep 5
done
