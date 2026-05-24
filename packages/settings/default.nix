{ pkgs, ... }:

let
  src = (import ../cleanPythonSource.nix { inherit (pkgs) lib; }) ./.;
  python = pkgs.python3.withPackages (ps: [
    ps.click
    ps.dbus-python
  ]);
in
pkgs.writeShellScriptBin "settings" ''
  exec ${python}/bin/python ${src}/settings.py "$@"
''
