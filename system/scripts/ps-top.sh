#!/usr/bin/env bash

export COLUMNS=500
if [[ "$(uname)" == "Darwin" ]]; then
  ps -eo pid,%cpu,command -r | head -11
else
  ps -eo pid,%cpu,command --sort=-%cpu | head -11
fi
