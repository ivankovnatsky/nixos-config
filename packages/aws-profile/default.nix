{ pkgs }:

pkgs.writeShellScriptBin "aws-profile" (builtins.readFile ./aws-profile.sh)
