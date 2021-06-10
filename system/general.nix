{ pkgs, ... }:

let editorName = "nvim";

in {
  environment = {
    homeBinInPath = true;

    variables = {
      EDITOR = editorName;
      VISUAL = editorName;
    };
  };

  documentation.enable = true;
  i18n.defaultLocale = "en_US.UTF-8";
  security.sudo.wheelNeedsPassword = false;
  sound.enable = true;
  time.timeZone = "Europe/Kiev";

  programs = {
    seahorse.enable = true;
    dconf.enable = true;
  };

  networking = {
    useDHCP = false;

    networkmanager = {
      enable = true;
      wifi.powersave = true;
    };
  };

  users.users.ivan = {
    description = "Ivan Kovnatsky";
    isNormalUser = true;
    home = "/home/ivan";
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "docker" "networkmanager" ];
  };

  fonts = {
    fonts = with pkgs; [
      (nerdfonts.override { fonts = [ "Hack" ]; })
      font-awesome
      noto-fonts
      noto-fonts-cjk
      noto-fonts-extra
      noto-fonts-emoji
    ];
  };

  security.rtkit.enable = true;
  security.pam.services.swaylock = { };
}
