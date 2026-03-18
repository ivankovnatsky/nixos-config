{ pkgs }:

pkgs.writeShellScriptBin "git-switch" (builtins.readFile ./git-switch.sh)
