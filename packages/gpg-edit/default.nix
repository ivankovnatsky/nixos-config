{ pkgs }:

pkgs.writeShellScriptBin "gpg-edit" (builtins.readFile ./gpg-edit.sh)
