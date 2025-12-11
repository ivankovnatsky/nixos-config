{ pkgs }:

pkgs.writeShellScriptBin "gh-pr" ''
  exec ${pkgs.python3}/bin/python ${./gh-pr.py} "$@"
''
