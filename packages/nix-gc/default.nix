{ pkgs }:

pkgs.writeShellScriptBin "nix-gc" (builtins.readFile ./nix-gc.sh)
