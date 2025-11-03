#!/usr/bin/env bash

while true; do
  pgrep -i kandji | grep ^[0-9] | xargs -I {} kill -9 {}
  sleep 5
done
