{ pkgs }:

pkgs.writeShellScriptBin "tmux-temperatures" (builtins.readFile ./tmux-temperatures.sh)
