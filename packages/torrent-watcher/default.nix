{ pkgs }:

pkgs.writeShellScriptBin "torrent-watcher" ''
  exec ${pkgs.fish}/bin/fish ${./torrent-watcher.fish} "$@"
''
