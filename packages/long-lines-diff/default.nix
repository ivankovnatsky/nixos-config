{ pkgs }:

pkgs.writeShellScriptBin "long-lines-diff" ''
  exec ${pkgs.python3}/bin/python3 ${./long-lines-diff.py} "$@"
''
