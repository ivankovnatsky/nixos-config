{ pkgs }:

pkgs.writeShellScriptBin "zscaler-kill" (builtins.readFile ./zscaler-kill.sh)
