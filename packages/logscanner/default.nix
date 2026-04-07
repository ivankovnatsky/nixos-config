{ pkgs }:

let
  src = ./.;
in
pkgs.writeShellScriptBin "logscanner" ''
  exec ${pkgs.python3}/bin/python ${src}/logscanner.py "$@"
''
