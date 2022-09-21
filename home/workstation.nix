{ config, pkgs, super, ... }:

let
  inherit (pkgs.stdenv.targetPlatform) isDarwin isLinux;

  editorName = "nvim";
  homeDir = if isDarwin then "/Users" else "/home";
  helmPluginsPath = if isDarwin then "Library/helm/plugins" else ".local/share/helm/plugins";
in
{
  imports = [
    ./alacritty.nix
    ./i3status.nix
    ./gtk.nix
    ./firefox.nix

    ../modules/secrets.nix
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
    grpcurl
    awscli2
    kubectl
    _1password
    alacritty
    bemenu
    file
    killall
    openssl
    whois
    zip
  ];

  device = super.device;
  variables = super.variables;
  secrets = super.secrets;
}
