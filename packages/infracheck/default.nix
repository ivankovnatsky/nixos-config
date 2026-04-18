{ pkgs }:

let
  src = ./.;
in
pkgs.writeShellScriptBin "infracheck" ''
  exec ${pkgs.python3.withPackages (ps: [ ps.click ])}/bin/python ${src}/infracheck.py "$@"
''
