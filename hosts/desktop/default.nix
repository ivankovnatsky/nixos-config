{ config, lib, pkgs, options, ... }:

{
  imports = [
    ./boot.nix
    ./hardware-configuration.nix

    ../../system/opengl-intel.nix
  ];

  networking.hostName = "desktop";

  device = {
    type = "desktop";
  };

  hardware.cpu.intel.updateMicrocode = true;

  system.stateVersion = "22.11";
}
