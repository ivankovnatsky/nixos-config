{ pkgs }:

pkgs.writeShellScriptBin "ghorg-sync" (builtins.readFile ./ghorg-sync.sh)
