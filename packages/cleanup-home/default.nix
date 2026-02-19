{ pkgs }:

pkgs.writeShellScriptBin "cleanup-home" ''
  exec ${pkgs.python3}/bin/python ${./cleanup-home.py} "$@"
''
