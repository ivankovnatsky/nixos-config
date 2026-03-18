{ pkgs }:

pkgs.writeShellScriptBin "nvim-edit-staged" (builtins.readFile ./nvim-edit-staged.sh)
