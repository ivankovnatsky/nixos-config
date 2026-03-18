{ pkgs }:

pkgs.writeShellScriptBin "tmux-attach" (builtins.readFile ./tmux-attach.sh)
