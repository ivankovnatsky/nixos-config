{ pkgs }:

pkgs.writeShellScriptBin "ssm-forward" (builtins.readFile ./ssm-forward.sh)
