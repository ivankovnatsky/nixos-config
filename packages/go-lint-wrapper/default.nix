{ pkgs }:

pkgs.writeShellScriptBin "go-lint-wrapper" (builtins.readFile ./go-lint-wrapper.sh)
