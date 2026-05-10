{ pkgs }:

pkgs.writeShellScriptBin "nextdns-mgmt" ''
  exec ${
    pkgs.python3.withPackages (ps: [
      ps.requests
      ps.click
      ps.dnspython
    ])
  }/bin/python ${./nextdns-mgmt.py} "$@"
''
