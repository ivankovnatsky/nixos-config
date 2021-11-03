#!/usr/bin/env bash

xidlehook \
  --not-when-fullscreen \
  --not-when-audio \
  --timer 300 \
    'xset dpms force off' \
    '' \
  --timer 600 \
    'i3lock -c "#000000"' \
    ''
