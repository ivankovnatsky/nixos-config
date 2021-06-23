{ config, lib, pkgs, options, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./boot.nix

    ../../system/bluetooth.nix
    ../../system/general.nix
    ../../system/greetd.nix
    ../../system/packages.nix
    ../../system/packages-linux.nix
    ../../system/programs.nix
    ../../system/services.nix
    ../../system/tlp.nix
    ../../system/upowerd.nix
  ];

  networking.hostName = "thinkpad";

  hardware = {
    # don't install all that firmware:
    # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/hardware/all-firmware.nix
    enableAllFirmware = false;
    enableRedistributableFirmware = false;
    firmware = with pkgs; [ firmwareLinuxNonfree ];

    cpu.amd.updateMicrocode = true;
  };

  nixpkgs.overlays = [ (import ../../system/overlays/linux) ];

  system.stateVersion = "21.03";
}
