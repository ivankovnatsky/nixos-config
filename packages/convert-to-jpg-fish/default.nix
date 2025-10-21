{ pkgs }:

pkgs.writeShellScriptBin "convert-to-jpg-fish" ''
  exec ${pkgs.fish}/bin/fish ${./convert-to-jpg-fish.fish} "$@"
''
