#!/usr/bin/env bash

if [[ "$(uname)" == "Darwin" ]]; then
  top -l 2 -n 10 -o cpu -stats pid,cpu,command | tail -12
else
  top -b -n 1 -o %CPU | head -17
fi
