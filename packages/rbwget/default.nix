{ pkgs }:

pkgs.writeShellScriptBin "rbwget" (builtins.readFile ./rbwget.sh)
