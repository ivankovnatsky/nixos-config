{ pkgs }:

let
  src = (import ../cleanPythonSource.nix { inherit (pkgs) lib; }) ./.;
in
pkgs.writeShellScriptBin "notes" ''
  exec ${
    pkgs.python3.withPackages (ps: [
      ps.click
    ])
  }/bin/python ${src}/notes.py "$@"
''
