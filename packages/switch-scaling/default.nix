{ pkgs }:

pkgs.writeShellScriptBin "switch-scaling" ''
  exec ${pkgs.python3}/bin/python3 ${./switch-scaling.py} "$@"
''
