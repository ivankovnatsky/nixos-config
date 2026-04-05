{ pkgs }:

pkgs.writeShellScriptBin "music-export" ''
  exec ${pkgs.python3.withPackages (ps: [ ps.click ])}/bin/python ${./music-export.py} "$@"
''
