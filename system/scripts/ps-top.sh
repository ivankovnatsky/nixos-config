#!/usr/bin/env bash

export COLUMNS=500
ps -eo pid,%cpu,args --sort=-%cpu | head -11
