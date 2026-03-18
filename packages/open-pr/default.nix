{ pkgs }:

pkgs.writeShellScriptBin "open-pr" ''
  exec ${pkgs.python3}/bin/python ${../gh-pr/gh-pr.py} "$@"
''
