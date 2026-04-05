{ pkgs }:

pkgs.writeShellScriptBin "gh-notifications" ''
  exec ${pkgs.python3.withPackages (ps: [ ps.click ])}/bin/python3 ${./gh-notifications.py} "$@"
''
