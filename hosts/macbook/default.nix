{ config, lib, pkgs, options, ... }:

{
  imports = [
    ../../system/darwin.nix
    ../../system/homebrew.nix
    ../../system/packages.nix
  ];

  homebrew.casks = [
    "coconutbattery"
  ];
}
