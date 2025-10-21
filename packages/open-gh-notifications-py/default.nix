{ pkgs }:

pkgs.writeShellScriptBin "open-gh-notifications-py" ''
  exec ${pkgs.python3}/bin/python3 ${./open-gh-notifications-py.py} "$@"
''
