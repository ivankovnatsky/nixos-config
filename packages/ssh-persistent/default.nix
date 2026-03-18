{ pkgs }:

pkgs.writeShellScriptBin "ssh-persistent" (builtins.readFile ./ssh-persistent.sh)
