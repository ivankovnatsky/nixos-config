{ pkgs }:

pkgs.writeShellScriptBin "create-pr" ''
  exec ${pkgs.python3}/bin/python ${../gh-pr/gh-pr.py} "$@"
''
