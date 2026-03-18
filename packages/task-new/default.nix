{ pkgs }:

pkgs.writeShellScriptBin "task-new" (builtins.readFile ./task-new.sh)
