{ pkgs }:

pkgs.writeShellScriptBin "power-consumption" ''
  exec ${pkgs.python3}/bin/python3 ${./power-consumption.py} "$@"
''
