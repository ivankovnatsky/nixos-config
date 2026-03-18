{ pkgs }:

pkgs.writeShellScriptBin "eat" (builtins.readFile ./eat.sh)
