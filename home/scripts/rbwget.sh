#!/usr/bin/env bash

item="$1"
rbw ls --fields name,user | fzf | xargs -r rbw get --field "$item" | sed 's/^.*: //' | pbcopy
