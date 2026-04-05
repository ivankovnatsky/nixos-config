{ pkgs }:

let
  src = ./.;
in
pkgs.writeShellScriptBin "abs" ''
  exec ${pkgs.python3.withPackages (ps: [ ps.click ])}/bin/python3 ${src}/abs.py "$@"
''
