{ pkgs }:

pkgs.writeShellScriptBin "mtdo" ''
  exec ${pkgs.python3}/bin/python3 ${./mtdo.py} "$@"
''
