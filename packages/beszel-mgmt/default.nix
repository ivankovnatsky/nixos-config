{ pkgs }:

let
  src = ./.;
in
pkgs.writeShellScriptBin "beszel-mgmt" ''
  exec ${
    pkgs.python3.withPackages (ps: [
      ps.requests
      ps.click
    ])
  }/bin/python ${src}/beszel-mgmt.py "$@"
''
