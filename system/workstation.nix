{ config, pkgs, ... }:

{
  imports = [
    ./chromium.nix
    ./nextdns.nix
    ./opengl.nix
  ];

  nixpkgs.overlays = [
    (
      self: super: {
        firefox = super.firefox-bin.override { forceWayland = true; };
      }
    )
  ];

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

      acpi
      brightnessctl
      gimp
      gnome3.adwaita-icon-theme
      libsecret
      libnotify
      networkmanagerapplet
      networkmanager-l2tp
      pavucontrol
      strace
      sysstat

      (google-chrome.override {
        commandLineArgs =
          "--force-dark-mode --use-vulkan --enable-gpu-rasterization --ozone-platform=wayland --flag-switches-begin --enable-features=VaapiVideoDecoder,UseOzonePlatform,ReaderMode,HardwareAccelerated,Vulkan,NativeNotifications,WebRTCPipeWireCapturer --flag-switches-end";
      })

      (chromium.override {
        commandLineArgs =
          "--force-dark-mode --use-vulkan --enable-gpu-rasterization --ozone-platform=wayland --flag-switches-begin --enable-features=VaapiVideoDecoder,UseOzonePlatform,ReaderMode,HardwareAccelerated,Vulkan,NativeNotifications,WebRTCPipeWireCapturer --flag-switches-end";
      })
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

  services = {
    xl2tpd.enable = true;
    fwupd.enable = true;
    gnome.gnome-keyring.enable = true;
    geoclue2.enable = true;
    journald.extraConfig = "SystemMaxUse=1G";
  };

  systemd = {
    services.NetworkManager-wait-online.enable = false;

    sleep.extraConfig = ''
      HibernateMode=shutdown
    '';
  };
}
