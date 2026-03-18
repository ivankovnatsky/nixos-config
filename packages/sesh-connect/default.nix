{ pkgs }:

pkgs.writeShellScriptBin "sesh-connect" (builtins.readFile ./sesh-connect.sh)
