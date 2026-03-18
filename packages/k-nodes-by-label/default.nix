{ pkgs }:

pkgs.writeShellScriptBin "k-nodes-by-label" (builtins.readFile ./k-nodes-by-label.sh)
