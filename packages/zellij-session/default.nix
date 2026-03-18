{ pkgs }:

pkgs.writeShellScriptBin "zellij-session" (builtins.readFile ./zellij-session.sh)
