#!/usr/bin/env bash

set -euo pipefail

case "$(uname -s)" in
Darwin)
  sudo /sbin/reboot
  ;;
Linux)
  if [[ -d /run/current-system ]]; then
    sudo /run/current-system/sw/bin/systemctl reboot
  else
    sudo /sbin/reboot
  fi
  ;;
*)
  echo "Unsupported OS: $(uname -s)" >&2
  exit 1
  ;;
esac
