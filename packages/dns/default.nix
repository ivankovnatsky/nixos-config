{ pkgs }:

pkgs.writeShellScriptBin "dns" ''
  exec ${pkgs.python3}/bin/python3 ${./dns.py} "$@"
''
