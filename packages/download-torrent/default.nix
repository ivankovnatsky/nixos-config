{ pkgs }:

pkgs.writeShellScriptBin "download-torrent" ''
  exec ${pkgs.fish}/bin/fish ${./download-torrent.fish} "$@"
''
