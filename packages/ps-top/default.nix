{ pkgs }:

pkgs.writeShellScriptBin "ps-top" (builtins.readFile ./ps-top.sh)
