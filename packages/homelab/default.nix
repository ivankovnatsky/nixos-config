{ pkgs }:

pkgs.writeShellScriptBin "homelab" ''
  exec ${pkgs.python3}/bin/python3 ${./homelab.py} "$@"
''
