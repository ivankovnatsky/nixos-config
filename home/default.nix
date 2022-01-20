{ config, pkgs, super, ... }:

{
  imports = [
    ./neovim
    ./alacritty.nix
    ./firefox.nix
    ./git.nix
    ./gtk.nix
    ./i3status.nix
    ./packages.nix
    ./tmux.nix
    ./zsh.nix

    ../modules/default.nix
    ../modules/secrets.nix
  ];

  programs.bat = {
    enable = true;
    config = { tabs = "0"; };
  };

  programs.go = {
    enable = true;

    goPath = "go";
  };

  programs.gpg.enable = true;

  services = {
    gpg-agent.enable = true;
  };

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

  programs.password-store = {
    enable = true;
    package = pkgs.pass.withExtensions (exts: [ exts.pass-otp ]);
  };

  home.packages = [ pkgs.ranger ];
  home.file = {
    ".config/ranger/rc.conf" = {
      text = ''
        set show_hidden true
      '';
    };
  };

  programs.taskwarrior = {
    enable = true;
    dataLocation = "/home/ivan/.task/";
  };

  home.file = {
    ".terraform.d/plugin-cache/.keep" = {
      text = ''
        keep
      '';
    };

    ".terraformrc" = {
      text = ''
        plugin_cache_dir = "$HOME/.terraform.d/plugin-cache"
      '';
    };

    ".config/yamllint/config" = {
      text = ''
        document-start: disable
      '';
    };
  };

  services = {
    ${config.variables.nightShiftManager} = {
      enable = true;

      latitude = "49.8";
      longitude = "29.9";

      temperature = {
        day = 5500;
        night = 3700;
      };
    };
  };

  device = super.device;
  variables = super.variables;
  secrets = super.secrets;
}
