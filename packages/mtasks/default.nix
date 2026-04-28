{ pkgs }:

pkgs.writeShellScriptBin "mtasks" ''
  exec ${pkgs.python3}/bin/python3 ${./mtasks.py} "$@"
''
