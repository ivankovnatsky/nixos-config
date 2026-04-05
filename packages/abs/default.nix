{ pkgs }:

let
  src = ./.;
in
pkgs.writeShellScriptBin "abs" ''
  exec ${pkgs.python3}/bin/python3 ${src}/abs.py "$@"
''
