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

    pulseaudio = {
      enable = true;
      extraModules = [ pkgs.pulseaudio-modules-bt ];
      package = pkgs.pulseaudioFull;
    };

    video.hidpi.enable = true;
  };

  hardware.bluetooth.config = {
    General = { Enable = "Source,Sink,Media,Socket"; };
  };

  hardware.pulseaudio.extraConfig =
    "\n  load-module module-switch-on-connect\n";
}
