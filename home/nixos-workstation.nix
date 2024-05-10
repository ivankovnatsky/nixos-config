{ pkgs, super, ... }:

{
  imports = [
    ./alacritty.nix
    ./i3status.nix
    ./gtk.nix
    ./firefox.nix
    ./firefox-config.nix

    ../modules/secrets
  ];

  programs.mpv = {
    enable = true;
    config = {
      "alang" = "eng";
      "force-seekable" = "yes";
      "fs" = "yes";
      "hwdec" = "yes";
      "opengl-pbo" = "yes";
      "osc" = "no";
      "osd-level" = "0";
      "save-position-on-quit" = "yes";
      "slang" = "eng";
      "ytdl-format" = "bestvideo+bestaudio/best";
      "image-display-duration" = "5";
      "vo" = "gpu";
      "profile" = "gpu-hq";
      "audio-channels" = 2;
    };
  };

  services = {
    redshift = {
      enable = true;
      provider = "geoclue2";

      temperature = {
        day = 5500;
        night = 3700;
      };
    };
  };

  home.packages = with pkgs; [
    smartmontools
    haskellPackages.dhall-yaml
    wl-clipboard
    alacritty
    bemenu
  ];

  device = super.device;
  flags = super.flags;
  secrets = super.secrets;
}
