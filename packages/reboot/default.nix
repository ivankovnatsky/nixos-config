{ pkgs }:

pkgs.writeShellScriptBin "reboot" (builtins.readFile ./reboot.sh)
