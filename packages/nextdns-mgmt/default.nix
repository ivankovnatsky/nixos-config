{ pkgs }:

pkgs.writeShellScriptBin "nextdns-mgmt" ''
  exec ${pkgs.python3.withPackages (ps: [ ps.requests ])}/bin/python ${./nextdns-mgmt.py} "$@"
''
