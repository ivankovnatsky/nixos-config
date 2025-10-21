{ pkgs }:

pkgs.writeShellScriptBin "audiobookshelf" ''
  exec ${pkgs.python3}/bin/python3 ${./audiobookshelf.py} "$@"
''
