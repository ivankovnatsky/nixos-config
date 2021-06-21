{ config, lib, pkgs, options, ... }:

{
  imports = [
    ../../system/homebrew.nix
    ../../system/packages.nix
    ../../system/packages-darwin.nix
  ];

  homebrew.casks = [
    "coconutbattery"
    "tidal"
  ];
}
