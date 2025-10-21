{ pkgs }:

pkgs.writeShellScriptBin "watch-torrent" ''
  exec ${pkgs.fish}/bin/fish ${./watch-torrent.fish} "$@"
''
