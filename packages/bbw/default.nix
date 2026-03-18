{ pkgs }:

pkgs.writeShellScriptBin "bbw" (builtins.readFile ./bbw.sh)
