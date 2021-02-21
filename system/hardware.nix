{ pkgs, ... }:

{
  hardware = {
    # don't install all that firmware:
    # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/hardware/all-firmware.nix
    enableAllFirmware = false;
    enableRedistributableFirmware = false;

    firmware = with pkgs; [ firmwareLinuxNonfree ];

    opengl = {
      enable = true;

      driSupport = true;
      driSupport32Bit = true;
    };

    bluetooth = {
      enable = true;
      powerOnBoot = false;
    };

    pulseaudio = {
      enable = true;
      extraModules = [ pkgs.pulseaudio-modules-bt ];
      package = pkgs.pulseaudioFull;
    };

    video.hidpi.enable = true;
  };

  hardware.bluetooth.settings = {
    General = { Enable = "Source,Sink,Media,Socket"; };
  };

  hardware.pulseaudio.extraConfig =
    "\n  load-module module-switch-on-connect\n";
}
