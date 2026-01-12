{ pkgs }:

pkgs.writeShellScriptBin "torrent-dl" ''
  exec ${pkgs.fish}/bin/fish ${./torrent-dl.fish} "$@"
''
