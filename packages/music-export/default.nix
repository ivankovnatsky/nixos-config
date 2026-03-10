{ pkgs }:

pkgs.writeShellScriptBin "music-export" ''
  exec ${pkgs.python3}/bin/python ${./music-export.py} "$@"
''
