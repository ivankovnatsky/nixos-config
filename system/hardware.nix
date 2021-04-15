{ pkgs, ... }:

{
  hardware = {
    # don't install all that firmware:
    # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/hardware/all-firmware.nix
    enableAllFirmware = false;
    enableRedistributableFirmware = false;
    firmware = with pkgs; [ firmwareLinuxNonfree ];

    cpu.amd.updateMicrocode = true;

    opengl = {
      enable = true;

      driSupport = true;
      driSupport32Bit = true;
    };

    video.hidpi.enable = true;
  };
}
