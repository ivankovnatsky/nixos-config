{ pkgs, ... }:

let
  settings = pkgs.callPackage ../settings { };
in
pkgs.writeShellScriptBin "volume-poweroff" ''
  exec ${settings}/bin/settings poweroff "$@"
''
