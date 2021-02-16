{ config, lib, pkgs, options, ... }:

{
  imports = [ # Include the results of the hardware scan.
    /etc/nixos/hardware-configuration.nix

    <home-manager/nixos>

    <nixos-hardware/lenovo/thinkpad/t14/amd/gen1>

    ./pkgs/environment.nix
    ./pkgs/hardware.nix
    ./pkgs/packages.nix
    ./pkgs/programs.nix
    ./pkgs/services.nix
    ./pkgs/xserver.nix

    ./i3.nix
  ];

  home-manager.users.ivan = { ... }: {
    imports = [ ../home/main.nix ];

    home.stateVersion = config.system.stateVersion;
  };

  boot = {
    initrd.luks.devices.crypted.device =
      "/dev/disk/by-uuid/28eb4c4d-9c50-44ae-b046-613c7eaac520";
    initrd.luks.devices.crypted.preLVM = true;

    kernelModules = [ "amdgpu" ];

    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
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

    nixPath = [
      "nixpkgs=https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz"

      "nixos-config=/etc/nixos/configuration.nix"
      "/nix/var/nix/profiles/per-user/root/channels"

      "home-manager=https://github.com/nix-community/home-manager/archive/master.tar.gz"

      "nixos-hardware=https://github.com/NixOS/nixos-hardware/archive/master.tar.gz"
    ];
  };

  users.users.ivan = {
    description = "Ivan Kovnatsky";
    isNormalUser = true;
    home = "/home/ivan";
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "docker" "networkmanager" ];
    uid = 1000;
  };

  virtualisation = {
    docker = {
      enable = false;
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
