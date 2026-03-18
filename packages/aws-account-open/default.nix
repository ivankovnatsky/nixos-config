{ pkgs }:

pkgs.writeShellScriptBin "aws-account-open" (builtins.readFile ./aws-account-open.sh)
