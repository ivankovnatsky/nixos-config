#!/usr/bin/env bash

# Complete 'ai' the same way as 'aichat'
# complete -c ai -w aichat

# Check if aichat is installed
if ! command -v aichat &> /dev/null; then
    echo "Error: aichat is not installed"
    echo "Please install it first: https://github.com/sigoden/aichat"
    exit 1
fi

# Pass all arguments directly to aichat
aichat "$@"
