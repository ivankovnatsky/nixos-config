#!/usr/bin/env bash

xidlehook \
  --not-when-fullscreen \
  --not-when-audio \
  --timer 150 \
    'xset dpms force off' \
    '' \
  --timer 300 \
    'i3lock -c "#000000"' \
    ''
