#!/usr/bin/env bash

set -x

find . -type f -name "*sync-conflict*" -delete
find . -type f -name "*syncthing*.tmp" -delete
