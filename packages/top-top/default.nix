{ pkgs }:

pkgs.writeShellScriptBin "top-top" (builtins.readFile ./top-top.sh)
