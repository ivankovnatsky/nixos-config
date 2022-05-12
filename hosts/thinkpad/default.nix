{ config, lib, pkgs, options, ... }:

{
  imports = [
    ./boot.nix
    ./hardware-configuration.nix

    ../../system/tlp.nix
    ../../system/upowerd.nix

    # ../../system/xserver-laptop.nix
  ];

  networking.extraHosts = '''';

  networking.hostName = "thinkpad";

  device = {
    monitorName = "DP-2";
  };

  hardware = {
    # don't install all that firmware:
    # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/hardware/all-firmware.nix
    enableAllFirmware = false;
    enableRedistributableFirmware = false;
    firmware = with pkgs; [ firmwareLinuxNonfree ];

    cpu.amd.updateMicrocode = true;
  };

  system.stateVersion = "21.03";
}
