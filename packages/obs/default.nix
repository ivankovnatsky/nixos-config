{ pkgs }:

pkgs.writeShellScriptBin "obs" ''
  exec ${pkgs.python3}/bin/python3 ${./obs.py} "$@"
''
