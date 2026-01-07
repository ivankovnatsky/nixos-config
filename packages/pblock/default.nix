{ pkgs }:

pkgs.writeShellScriptBin "pblock" ''
  exec ${pkgs.python3}/bin/python3 ${./pblock.py} "$@"
''
