{ pkgs }:

pkgs.writeShellScriptBin "watcher" ''
  exec ${pkgs.fish}/bin/fish ${./watcher.fish} "$@"
''
