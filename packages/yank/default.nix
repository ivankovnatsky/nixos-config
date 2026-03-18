{ pkgs }:

pkgs.writeShellScriptBin "yank" (builtins.readFile ../eat/eat.sh)
