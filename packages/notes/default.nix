{ pkgs }:

let
  src = ./.;
in
pkgs.writeShellScriptBin "notes" ''
  exec ${
    pkgs.python3.withPackages (ps: [
      ps.click
    ])
  }/bin/python ${src}/notes.py "$@"
''
