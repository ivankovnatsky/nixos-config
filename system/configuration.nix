{ config, lib, pkgs, ... }:

{
  imports = [ # Include the results of the hardware scan.
    ./hardware-configuration.nix

    <home-manager/nixos>

    <nixos-hardware/lenovo/thinkpad/t14/amd/gen1>

    ./modules/environment.nix
    ./modules/hardware.nix
    ./modules/packages.nix
    ./modules/programs.nix
    ./modules/services.nix
    ./modules/xserver.nix

    ./modules/i3.nix
    # ./modules/dwm.nix
    # ./modules/gnome.nix
  ];

  powerManagement.powertop.enable = true;

  systemd.sleep.extraConfig = ''
    HibernateMode=shutdown
  '';

  home-manager.users.ivan = { ... }: {
    imports = [ ../home/main.nix ];
    home.stateVersion = config.system.stateVersion;
  };

  networking = {
    hostName = "thinkpad";

    networkmanager = {
      enable = true;
      enableStrongSwan = true;
      wifi.powersave = true;
    };

    useDHCP = false;
  };

  documentation.enable = false;

  time.timeZone = "Europe/Kiev";
  i18n.defaultLocale = "en_US.UTF-8";
  sound.enable = true;
  security.sudo.wheelNeedsPassword = false;
  nixpkgs.config.allowUnfree = true;

  nix = {
    autoOptimiseStore = true;
    gc.automatic = true;
    optimise.automatic = true;
  };

  users.users.ivan = {
    description = "Ivan Kovnatsky";
    isNormalUser = true;
    home = "/home/ivan";
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "docker" "networkmanager" ];
  };

  virtualisation = {
    docker = {
      enable = true;
      enableOnBoot = false;
    };
  };

  fonts = {
    fonts = with pkgs; [
      (nerdfonts.override { fonts = [ "Hack" ]; })
      font-awesome
      noto-fonts
      noto-fonts-cjk
      noto-fonts-extra
    ];
  };

  system.stateVersion = "21.03";
}
