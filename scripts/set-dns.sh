#!/usr/bin/env bash

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: set-dns <interface> [dns1 dns2 ...]"
  echo ""
  echo "Examples:"
  echo "  set-dns wifi 1.1.1.1 1.0.0.1"
  echo "  set-dns eth 8.8.8.8 8.8.4.4"
  echo "  set-dns wifi empty  # Clear DNS (use DHCP)"
  echo "  set-dns eth empty   # Clear DNS (use DHCP)"
  exit 1
fi

interface="$1"
shift

# Map to actual network service names
case "${interface,,}" in
  wifi|wi-fi)
    service="Wi-Fi"
    ;;
  ethernet|eth)
    service="Thunderbolt Ethernet Slot 1"
    ;;
  *)
    echo "Unknown interface: $interface"
    echo "Use 'wifi' or 'eth'"
    exit 1
    ;;
esac

# Handle empty/clear case
if [ $# -eq 1 ] && [[ "${1,,}" == "empty" ]]; then
  echo "Clearing DNS servers for $service..."
  networksetup -setdnsservers "$service" Empty
else
  echo "Setting DNS servers for $service to: $*"
  networksetup -setdnsservers "$service" "$@"
fi

echo ""
echo "Current DNS servers:"
networksetup -getdnsservers "$service"
