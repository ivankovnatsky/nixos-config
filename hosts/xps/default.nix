{ config, lib, pkgs, options, ... }:

{
  imports = [
    ./boot.nix
    ./hardware-configuration.nix

    ../../system/opengl-intel.nix
    ../../system/upowerd.nix
  ];

  networking.hostName = "xps";

  hardware = {
    enableAllFirmware = true;
    enableRedistributableFirmware = true;
    firmware = with pkgs; [ firmwareLinuxNonfree ];

    cpu.intel.updateMicrocode = true;
  };

  device = {
    monitorName = "DP-3";
  };

  services.logind.lidSwitch = "ignore";

  system.stateVersion = "22.05";
}
