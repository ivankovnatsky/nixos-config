{ pkgs, ... }:

{
  hardware = {
    opengl = {
      driSupport = true;
      driSupport32Bit = true;
    };

    bluetooth = {
      enable = true;
      powerOnBoot = false;
    };

    video.hidpi.enable = true;

    pulseaudio = {
      enable = true;
      extraModules = [ pkgs.pulseaudio-modules-bt ];
      package = pkgs.pulseaudioFull;
    };
  };

  hardware.bluetooth.config = {
    General = { Enable = "Source,Sink,Media,Socket"; };
  };

  hardware.pulseaudio.extraConfig =
    "\n  load-module module-switch-on-connect\n";
}
