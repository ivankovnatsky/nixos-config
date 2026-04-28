{ pkgs }:

pkgs.writeShellScriptBin "mdo" ''
  exec ${pkgs.python3}/bin/python3 ${./mdo.py} "$@"
''
