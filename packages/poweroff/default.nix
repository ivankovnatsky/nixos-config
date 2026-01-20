{ pkgs, ... }:

let
  settings = pkgs.callPackage ../settings { };
in
pkgs.writeShellScriptBin "poweroff" ''
  exec ${settings}/bin/settings poweroff "$@"
''
