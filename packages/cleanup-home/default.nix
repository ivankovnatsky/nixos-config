{ pkgs }:

pkgs.writeShellScriptBin "cleanup-home" ''
  exec ${pkgs.python3.withPackages (ps: [ ps.click ])}/bin/python ${./cleanup-home.py} "$@"
''
