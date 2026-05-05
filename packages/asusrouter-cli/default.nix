{ pkgs }:

let
  src = (import ../cleanPythonSource.nix { inherit (pkgs) lib; }) ./.;
in
pkgs.writeShellScriptBin "asusrouter-cli" ''
  exec ${
    pkgs.python3.withPackages (ps: [
      ps.asusrouter
      ps.click
    ])
  }/bin/python ${src}/asusrouter-cli.py "$@"
''
