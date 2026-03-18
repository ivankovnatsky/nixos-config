{ pkgs }:

pkgs.writeShellScriptBin "git-root-root" (builtins.readFile ./git-root-root.sh)
