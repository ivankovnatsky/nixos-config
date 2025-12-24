#!/usr/bin/env sh

# Script to remotely power off homelab machines
# Usage: ./power-off-homelab.sh
# This script will power off the Mini

set -e

# Clear local DNS settings before shutting down Mini (which hosts DNS)
dns clear

ssh ivan@192.168.50.4 "sudo shutdown -h now"
