{ pkgs, ... }:

let
  src = (import ../cleanPythonSource.nix { inherit (pkgs) lib; }) ./.;
  python = pkgs.python3.withPackages (ps: [
    ps.click
    ps.dbus-python
  ]);
in
pkgs.writeShellApplication {
  name = "settings";
  runtimeInputs = pkgs.lib.optionals pkgs.stdenv.isLinux [ pkgs.pulseaudio ];
  text = ''
    exec ${python}/bin/python ${src}/settings.py "$@"
  '';
}
