{ pkgs, ... }:

let
  settings = pkgs.callPackage ../settings { };
in
pkgs.writeShellScriptBin "turnoff" ''
  exec ${settings}/bin/settings turnoff "$@"
''
