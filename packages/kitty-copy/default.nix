{ pkgs }:

pkgs.writeShellScriptBin "kitty-copy" (builtins.readFile ./kitty-copy.sh)
