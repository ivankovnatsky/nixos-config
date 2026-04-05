{ pkgs }:

pkgs.writeShellScriptBin "gh-pr" ''
  exec ${pkgs.python3.withPackages (ps: [ ps.click ])}/bin/python ${./gh-pr.py} "$@"
''
