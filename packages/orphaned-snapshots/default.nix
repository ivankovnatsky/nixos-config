{ pkgs }:

pkgs.writeShellScriptBin "orphaned-snapshots" (builtins.readFile ./orphaned-snapshots.sh)
