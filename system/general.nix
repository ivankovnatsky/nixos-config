{ pkgs, ... }:

{
  boot = {
    loader = {
      timeout = 1;

      systemd-boot = {
        enable = true;
        configurationLimit = 5;
      };

      efi.canTouchEfiVariables = true;
    };

    tmpOnTmpfs = true;
  };

  documentation = {
    enable = true;
    man.enable = true;
    info.enable = false;
  };

  i18n.defaultLocale = "en_US.UTF-8";
  sound.enable = true;

  hardware = {
    opengl = {
      enable = true;

      driSupport = true;
      driSupport32Bit = true;
    };
  };

  programs = {
    seahorse.enable = true;
    dconf.enable = true;
  };

  networking = {
    useDHCP = false;
    networkmanager.enableStrongSwan = true;
    wireless.iwd.enable = true;

    networkmanager = {
      enable = true;

      wifi.backend = "iwd";
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
      noto-fonts
      noto-fonts-cjk
      noto-fonts-extra
      noto-fonts-emoji
    ];
  };

  xdg = {
    icons.enable = true;

    portal = {
      enable = true;
      gtkUsePortal = true;

      extraPortals = with pkgs; [
        xdg-desktop-portal-wlr
        xdg-desktop-portal-gtk
      ];
    };
  };

  security = {
    rtkit.enable = true;
    pam.services.swaylock = { };
    sudo.configFile = ''
      Defaults timestamp_timeout=240
    '';
  };
}
