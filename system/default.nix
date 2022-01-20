{ pkgs, ... }:

let editorName = "nvim";

in
{
  imports = [
    ./chromium.nix
    ./nextdns.nix
    ./opengl.nix
    ./packages.nix
    ./services.nix

    ../modules/default.nix
    ../modules/secrets.nix
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
  };

  environment = {
    variables = {
      AWS_VAULT_BACKEND = "pass";
      EDITOR = editorName;
      LPASS_AGENT_TIMEOUT = "0";
      VISUAL = editorName;
    };
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;

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

  environment.systemPackages = with pkgs; [
    xdg-utils
    pulseaudio
  ];

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

  nix.autoOptimiseStore = true;

  nixpkgs.config.allowUnfree = true;

  users.users.ivan = {
    description = "Ivan Kovnatsky";
    isNormalUser = true;
    home = "/home/ivan";
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "docker" "networkmanager" ];
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
    package = pkgs.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };
}
