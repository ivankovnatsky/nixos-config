{ pkgs }:

pkgs.writeShellScriptBin "set-dns" ''
  exec ${pkgs.python3}/bin/python3 ${./set-dns.py} "$@"
''
