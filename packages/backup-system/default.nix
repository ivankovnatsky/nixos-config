{ pkgs }:

pkgs.writeShellScriptBin "backup-system" (builtins.readFile ./backup-system.sh)
