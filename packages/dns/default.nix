{ pkgs }:

pkgs.writeShellScriptBin "dns" ''
  exec ${pkgs.python3.withPackages (ps: [ ps.click ])}/bin/python3 ${./dns.py} "$@"
''
