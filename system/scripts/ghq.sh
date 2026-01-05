#!/usr/bin/env bash
# Wrapper for ghq get with auto-update enabled
# ghq doesn't support config-based auto-update, only -u CLI flag
# https://github.com/x-motemen/ghq
exec ghq get -u "$@"
