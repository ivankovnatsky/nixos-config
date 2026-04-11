{ pkgs }:

let
  src = ./.;
in
pkgs.writeShellScriptBin "logscanner" ''
  exec ${pkgs.python3.withPackages (ps: [ ps.click ])}/bin/python ${src}/logscanner.py "$@"
''
