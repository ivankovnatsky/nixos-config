{ pkgs }:

pkgs.writeShellScriptBin "diff-deep" (builtins.readFile ./diff-deep.sh)
