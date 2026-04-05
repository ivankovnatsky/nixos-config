{ pkgs }:

let
  src = ./.;
in
pkgs.writeShellScriptBin "uptime-kuma-mgmt" ''
  exec ${
    pkgs.python3.withPackages (ps: [
      ps.uptime-kuma-api
      ps.requests
      ps.websocket-client
    ])
  }/bin/python ${src}/uptime-kuma-mgmt.py "$@"
''
