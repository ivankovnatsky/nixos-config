{ pkgs }:

pkgs.writeShellScriptBin "pblock" ''
  exec ${pkgs.python3.withPackages (ps: [ ps.click ])}/bin/python3 ${./pblock.py} "$@"
''
