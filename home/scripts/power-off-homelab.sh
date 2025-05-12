#!/usr/bin/env sh

# Script to remotely power off homelab machines
# Usage: ./power-off-homelab.sh
# This script will power off both the Bee machine and the Mini

set -e

# Define machines list as space-separated string (POSIX compatible)
HOSTS="bee ivans-mac-mini"

# Function to power off a specific machine
power_off_machine() {
  host=$1
  ssh ivan@"$host" "sudo shutdown -h now"
}

# Power off all machines in the list
for host in $HOSTS; do
  power_off_machine "$host"
done
