#!/usr/bin/env bash

ps -eo pid,comm,%cpu | head -1
ps -eo pid,comm,%cpu | tail -n +2 | sort -k3 -rn | head -5
