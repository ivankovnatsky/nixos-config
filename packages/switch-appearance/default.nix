{ pkgs }:

pkgs.writeShellScriptBin "switch-appearance" ''
  exec ${pkgs.fish}/bin/fish ${./switch-appearance.fish} "$@"
''
