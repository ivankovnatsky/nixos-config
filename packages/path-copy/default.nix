{ pkgs }:

pkgs.writeShellScriptBin "path-copy" (builtins.readFile ./path-copy.sh)
