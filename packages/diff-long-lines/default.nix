{ pkgs }:

pkgs.writeShellScriptBin "diff-long-lines" ''
  exec ${pkgs.python3.withPackages (ps: [ ps.click ])}/bin/python3 ${./diff-long-lines.py} "$@"
''
