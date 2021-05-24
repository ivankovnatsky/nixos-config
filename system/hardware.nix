{ pkgs, ... }:

{
  hardware = {
    # don't install all that firmware:
    # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/hardware/all-firmware.nix
    enableAllFirmware = false;
    enableRedistributableFirmware = false;
    firmware = with pkgs; [ firmwareLinuxNonfree ];

    cpu.amd.updateMicrocode = true;

    bluetooth = {
      enable = true;
      powerOnBoot = false;
    };

    video.hidpi.enable = true;
  };

  hardware.bluetooth.settings = {
    General = { Enable = "Source,Sink,Media,Socket"; };
  };
}
