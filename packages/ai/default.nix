{ pkgs }:

pkgs.writeShellScriptBin "ai" (builtins.readFile ./ai.sh)
