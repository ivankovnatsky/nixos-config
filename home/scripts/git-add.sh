#!/usr/bin/env bash

# git-add.sh

# Add all files in git-root

git add "$(git rev-parse --show-toplevel)"
