{ pkgs }:

pkgs.writeShellScriptBin "gpg-pass-refresh" (builtins.readFile ./gpg-pass-refresh.sh)
