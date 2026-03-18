{ pkgs }:

pkgs.writeShellScriptBin "statix-wrapper" (builtins.readFile ./statix-wrapper.sh)
