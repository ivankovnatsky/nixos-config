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
# ```
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
# ```
# nix-collect-garbage -d
# ```
#
# nix gc is the second command, because it will clean it up home-manager
# generations once we delete them.

nix_gc() {
    nix-collect-garbage -d
}

home_manager_gc() {
    local generations
    # We need to list everything except the first generation, which is at the
    # top of the list and is the current generation.
    generations=$(home-manager generations | tail -n +2 | awk '{print $5}')
    for g in $generations; do
        home-manager remove-generations "$g"
    done
}

home_manager_gc
nix_gc
