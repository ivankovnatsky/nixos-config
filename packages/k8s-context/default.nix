{ pkgs }:

pkgs.writeShellScriptBin "k8s-context" (builtins.readFile ./k8s-context.sh)
