{ pkgs }:

pkgs.writeShellScriptBin "gh-notifications" ''
  exec ${pkgs.python3}/bin/python3 ${./gh-notifications.py} "$@"
''
