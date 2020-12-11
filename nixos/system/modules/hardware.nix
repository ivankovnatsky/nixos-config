{ pkgs, ... }:

{
  hardware = {
    opengl = {
      driSupport = true;
      driSupport32Bit = true;
    };

    video.hidpi.enable = true;
    pulseaudio.enable = true;
  };
}
