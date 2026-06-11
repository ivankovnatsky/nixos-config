{ pkgs, ... }:

let
  settings = pkgs.callPackage ../settingsctl { };
in
pkgs.writeShellApplication {
  name = "turnoff";
  runtimeInputs = pkgs.lib.optionals pkgs.stdenv.isLinux [ pkgs.pulseaudio ];
  text = ''
    exec ${settings}/bin/settings turnoff "$@"
  '';
}
