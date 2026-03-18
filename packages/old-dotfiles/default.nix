{ pkgs }:

pkgs.writeShellScriptBin "old-dotfiles" (builtins.readFile ./old-dotfiles.sh)
