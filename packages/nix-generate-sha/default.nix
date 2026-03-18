{ pkgs }:

pkgs.writeShellScriptBin "nix-generate-sha" (builtins.readFile ./nix-generate-sha.sh)
