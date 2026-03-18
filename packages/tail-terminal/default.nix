{ pkgs }:

pkgs.writeShellScriptBin "tail-terminal" (builtins.readFile ./tail-terminal.sh)
