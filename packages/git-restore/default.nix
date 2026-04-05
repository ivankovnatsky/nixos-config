{ pkgs }:

pkgs.writeShellScriptBin "git-restore" ''
  exec ${pkgs.python3.withPackages (ps: [ ps.click ])}/bin/python ${./git-restore.py} "$@"
''
