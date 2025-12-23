#!/usr/bin/env sh

# Script to remotely power off homelab machines
# Usage: ./power-off-homelab.sh
# This script will power off the Mini

set -e

ssh ivan@ivans-mac-mini.local "sudo shutdown -h now"
