{ pkgs, python3Packages }:

pkgs.writeShellScriptBin "uptime-kuma-mgmt" ''
  exec ${
    pkgs.python3.withPackages (ps: [
      ps.uptime-kuma-api
      ps.requests
      ps.websocket-client
    ])
  }/bin/python ${./uptime-kuma-mgmt.py} "$@"
''
