{ pkgs }:

let
  src = (import ../cleanPythonSource.nix { inherit (pkgs) lib; }) ./.;
in
pkgs.writeShellScriptBin "syncthing-mgmt" ''
  exec ${
    pkgs.python3.withPackages (ps: [
      ps.requests
      ps.bcrypt
      ps.rich
      ps.click
    ])
  }/bin/python ${src}/syncthing-mgmt.py "$@"
''
