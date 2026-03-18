{ pkgs }:

pkgs.writeShellScriptBin "game-mode" (builtins.readFile ./game-mode.sh)
