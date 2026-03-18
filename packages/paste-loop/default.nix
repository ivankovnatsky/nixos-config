{ pkgs }:

pkgs.writeShellScriptBin "paste-loop" (builtins.readFile ./paste-loop.sh)
