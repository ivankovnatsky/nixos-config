{ pkgs }:

pkgs.writeShellScriptBin "abs" ''
  exec ${pkgs.python3}/bin/python3 ${./abs.py} "$@"
''
