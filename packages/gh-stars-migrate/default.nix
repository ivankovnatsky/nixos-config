{ pkgs }:

pkgs.writeShellScriptBin "gh-stars-migrate" (builtins.readFile ./gh-stars-migrate.sh)
