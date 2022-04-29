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
    graphicsEnv = "xorg";
  };

  services.logind = {
    extraConfig = "HandlePowerKey=hibernate";
    lidSwitch = "hibernate";
  };

  system.stateVersion = "22.05";
}
