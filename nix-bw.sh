#!/usr/bin/env bash

set -euo pipefail

f=$(mktemp)
trap "rm $f" EXIT
sudo -u ivan bw get password "$1" |tr -d "\n" > "$f"
nix-instantiate --eval -E "builtins.readFile $f"
