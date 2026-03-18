{ pkgs }:

pkgs.writeShellScriptBin "tac" (builtins.readFile ./tac.sh)
