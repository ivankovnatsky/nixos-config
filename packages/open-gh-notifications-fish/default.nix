{ pkgs }:

pkgs.writeShellScriptBin "open-gh-notifications-fish" ''
  exec ${pkgs.fish}/bin/fish ${./open-gh-notifications-fish.fish} "$@"
''
