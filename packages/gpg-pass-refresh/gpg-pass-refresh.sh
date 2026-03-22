#!/usr/bin/env bash

set -euo pipefail

gpg --sign --default-key "75213+ivankovnatsky@users.noreply.github.com" -o /dev/null /dev/null
echo "GPG passphrase cached."
