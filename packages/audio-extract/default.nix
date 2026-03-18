{ pkgs }:

pkgs.writeShellScriptBin "audio-extract" (builtins.readFile ./audio-extract.sh)
