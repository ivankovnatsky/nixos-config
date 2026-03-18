{ pkgs }:

pkgs.writeShellScriptBin "git-repo-dl" (builtins.readFile ./git-repo-dl.sh)
