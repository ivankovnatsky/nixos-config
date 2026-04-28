{ pkgs }:

pkgs.writeShellScriptBin "temperatures" ''
  exec ${pkgs.python3.withPackages (ps: [ ps.click ])}/bin/python3 ${./temperatures.py} "$@"
''
