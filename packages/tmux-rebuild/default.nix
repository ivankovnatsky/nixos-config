{ pkgs }:

pkgs.writeShellScriptBin "tmux-rebuild" (builtins.readFile ./tmux-rebuild.sh)
