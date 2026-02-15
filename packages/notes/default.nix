{ pkgs }:

pkgs.writeShellScriptBin "notes" ''
  exec ${pkgs.python3}/bin/python3 ${./notes.py} "$@"
''
