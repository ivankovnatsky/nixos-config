{ pkgs }:

pkgs.writeShellScriptBin "power-consumption" ''
  exec ${pkgs.python3.withPackages (ps: [ ps.click ])}/bin/python3 ${./power-consumption.py} "$@"
''
