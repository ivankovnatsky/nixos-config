{ pkgs, ... }:

let
  settings = pkgs.callPackage ../settings { };
in
pkgs.writeShellScriptBin "poweroff" ''
  # Set volume to 2.5% (quarter of 10%) before shutdown
  ${settings}/bin/settings volume 2.5

  # Shutdown the system
  sudo shutdown -h now
''
