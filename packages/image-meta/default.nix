{ pkgs }:

pkgs.writeShellScriptBin "image-meta" (builtins.readFile ./image-meta.sh)
