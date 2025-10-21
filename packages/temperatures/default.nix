{ pkgs }:

pkgs.writeShellScriptBin "temperatures" ''
  exec ${pkgs.python3}/bin/python3 ${./temperatures.py} "$@"
''
