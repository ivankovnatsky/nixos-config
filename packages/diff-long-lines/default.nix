{ pkgs }:

pkgs.writeShellScriptBin "diff-long-lines" ''
  exec ${pkgs.python3}/bin/python3 ${./diff-long-lines.py} "$@"
''
