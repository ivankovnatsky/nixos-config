{ config, pkgs, ... }:

{
  imports = [
    ./chromium.nix
    ./nextdns.nix
    ./opengl.nix
    ./packages.nix
    ./services.nix
  ];

  boot = {
    loader = {
      timeout = 1;

      systemd-boot = {
        enable = true;
        configurationLimit = 5;
      };

      efi.canTouchEfiVariables = true;
    };
  };

  services.teamviewer.enable = true;

  nixpkgs.overlays = [
    (
      self: super: {
        firefox = super.firefox-bin.override { forceWayland = true; };
      }
    )
  ];

  documentation = {
    enable = true;
    man.enable = true;
    info.enable = false;
  };

  fonts = {
    fonts = with pkgs; [
      (nerdfonts.override { fonts = [ "Hack" ]; })
      noto-fonts
      noto-fonts-cjk
      noto-fonts-extra
      noto-fonts-emoji
    ];

    fontconfig = {
      enable = true;
      antialias = true;
      defaultFonts = {
        monospace = [ "${config.variables.fontMono}" ];
      };
    };

    fontDir.enable = true;
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;

    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true;
      };
    };
  };

  hardware.video.hidpi.enable = true;
  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "Europe/Kiev";
  sound.enable = true;

  networking = {
    useDHCP = false;

    networkmanager = {
      enable = true;

      wifi.powersave = true;
    };
  };

  programs = {
    seahorse.enable = true;
    dconf.enable = true;
  };

  environment = {
    systemPackages = with pkgs; [
      xdg-utils
      pulseaudio
    ];
  };

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  xdg = {
    portal = {
      enable = true;

      extraPortals = with pkgs; [
        xdg-desktop-portal-wlr
      ];
    };
  };

  services = {
    pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };
  };

  security = {
    rtkit.enable = true;
    sudo.configFile = ''
      Defaults timestamp_timeout=240
    '';
  };

  nixpkgs.config.allowUnfree = true;

  users.users.ivan = {
    description = "Ivan Kovnatsky";
    isNormalUser = true;
    home = "/home/ivan";
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "networkmanager" "docker" ];
  };

  xdg = {
    icons.enable = true;

    mime = {
      enable = true;
      defaultApplications = {
        "application/pdf" = "firefox.desktop";
        "image/png" = "firefox.desktop";
        "image/jpeg" = "firefox.desktop";
      };
    };
  };

  nix = {
    settings = {
      auto-optimise-store = true;
    };
  };
}
