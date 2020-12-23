{ pkgs, ... }:

{
  hardware = {
    opengl = {
      driSupport = true;
      driSupport32Bit = true;
    };

    bluetooth.enable = false;
    video.hidpi.enable = true;
    pulseaudio.enable = true;
  };
}
