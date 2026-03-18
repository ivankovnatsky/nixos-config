{ pkgs }:

pkgs.writeShellScriptBin "yt-dlp-parallel" (builtins.readFile ./yt-dlp-parallel.sh)
