#!/usr/bin/env bash

ACTION="get"
FIELD="item"

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --get)
        ACTION="get"
        FIELD="$2"
        shift 2
        ;;
        *)
        echo "Usage: $0 [--get username|password|<field>]"
        exit 1
        ;;
    esac
done

item=$(bw list items | jq -r 'map(.name) | .[]' | fzf)
id=$(bw list items --search "${item}" | jq -r ".[0].id")

if [ "$ACTION" == "get" ]; then
    bw get item "${id}" | jq -r ".login.${FIELD}"
fi
