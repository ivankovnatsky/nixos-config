{ pkgs }:

pkgs.writeShellScriptBin "git-branch" (builtins.readFile ./git-branch.sh)
