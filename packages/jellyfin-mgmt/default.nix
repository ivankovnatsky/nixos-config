{ pkgs }:

let
  src = ./.;
in
pkgs.writeShellScriptBin "jellyfin-mgmt" ''
  exec ${
    pkgs.python3.withPackages (ps: [
      ps.requests
      ps.click
    ])
  }/bin/python ${src}/jellyfin-mgmt.py "$@"
''
