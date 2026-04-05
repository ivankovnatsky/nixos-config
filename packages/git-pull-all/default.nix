{ pkgs }:

pkgs.writeShellScriptBin "git-pull-all" ''
  exec ${pkgs.python3.withPackages (ps: [ ps.click ])}/bin/python3 ${./git-pull-all.py} "$@"
''
