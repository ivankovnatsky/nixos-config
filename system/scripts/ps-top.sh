#!/usr/bin/env bash

export COLUMNS=500
ps -eo pid,%cpu,command -r | head -11
