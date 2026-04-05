{ pkgs }:

let
  src = ./.;
in
pkgs.writeShellScriptBin "arr-mgmt" ''
  exec ${pkgs.python3.withPackages (ps: [ ps.requests ])}/bin/python ${src}/arr-mgmt.py "$@"
''
