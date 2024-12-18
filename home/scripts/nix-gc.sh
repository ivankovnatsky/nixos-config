#!/usr/bin/env bash

# Since home-manager does not support nix gc of it's generations:
#
# * https://github.com/nix-community/home-manager/issues/4204#issue-1790502052
# * https://github.com/nix-community/home-manager/issues/3450
#
# We can clean it up combining two commands:
#
# 1.
#
# ```console
# ❯ home-manager generations
# 2023-10-18 12:39 : id 1163 -> /nix/store/jhnjszgsni1a94aff7f31jj3hzg7n757-home-manager-generation
# ...
# 2023-10-12 19:20 : id 1144 -> /nix/store/44la87nfymkvczy6lnfjz8i78r9d6fgc-home-manager-generation
#
# for g in {1144..1162};do home-manager remove-generations $g;done
# ```
#
# 2.
#
# ```console
# nix-collect-garbage -d
# ```
#
# nix gc is the second command, because it will clean it up home-manager
# generations once we delete them.

# Disable pager globally.
export PAGER=""

nix_gc() {
    # List nix generations.
    # Example: nix-env --list-generations
    #
    # ```console
    #    3   2022-10-04 10:51:55   (current)
    # ```
    nix-env --list-generations
    sudo nix-env --profile /nix/var/nix/profiles/system --list-generations

    nix-collect-garbage -d
    sudo nix-collect-garbage -d
}

home_manager_gc() {
    local generations
    local current_generation

    # Get and show the current (first) generation
    current_generation=$(home-manager generations | head -n 1)
    echo "Current home-manager generation:"
    echo "$current_generation"
    echo

    # Get all generations except the current one
    generations=$(home-manager generations | tail -n +2 | awk '{print $5}')
    if [[ -n $generations ]]; then
        for g in $generations; do
            home-manager remove-generations "$g"
        done
    else
        echo "No home-manager generations to remove"
    fi
}

home_manager_gc
nix_gc
