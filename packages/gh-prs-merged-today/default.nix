{ pkgs }:

pkgs.writeShellScriptBin "gh-prs-merged-today" (builtins.readFile ./gh-prs-merged-today.sh)
