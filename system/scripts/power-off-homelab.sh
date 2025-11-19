#!/usr/bin/env sh

# Script to remotely power off homelab machines
# Usage: ./power-off-homelab.sh
# This script will power off both the Bee machine and the Mini

set -e

ssh ivan@bee "sudo shutdown -h now"
ssh ivan@ivans-mac-mini.local "sudo shutdown -h now"
