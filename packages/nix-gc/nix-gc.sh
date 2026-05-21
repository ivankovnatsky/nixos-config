#!/usr/bin/env bash

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

nix_gc
