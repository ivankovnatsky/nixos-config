{ pkgs }:

pkgs.writeShellScriptBin "pass-fzf" (builtins.readFile ./pass-fzf.sh)
