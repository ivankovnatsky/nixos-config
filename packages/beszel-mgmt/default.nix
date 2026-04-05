{ pkgs }:

let
  src = ./.;
in
pkgs.writeShellScriptBin "beszel-mgmt" ''
  exec ${pkgs.python3.withPackages (ps: [ ps.requests ])}/bin/python ${src}/beszel-mgmt.py "$@"
''
