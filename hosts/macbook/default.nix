{ config, lib, pkgs, options, ... }:

{
  imports = [
    ../../system/environment.nix
    ../../system/homebrew.nix
    ../../system/nix.nix
    ../../system/packages.nix
    ../../system/packages-darwin.nix
  ];

  homebrew.casks = [
    "coconutbattery"
    "tidal"
  ];
}
