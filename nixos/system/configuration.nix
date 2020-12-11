{ config, lib, pkgs, ... }:

{
  imports = [ # Include the results of the hardware scan.
    /etc/nixos/hardware-configuration.nix

    <nixos-hardware/lenovo/thinkpad/t14/amd/gen1>

    ./modules/environment.nix
    ./modules/hardware.nix
    ./modules/neovim.nix
    ./modules/packages.nix
    ./modules/programs.nix
    ./modules/services.nix
    ./modules/tmux.nix
    ./modules/xserver.nix
    ./modules/zsh.nix

    # ./modules/terraform.nix
  ];

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
    networkmanager.enableStrongSwan = true;

    useDHCP = false;
    networkmanager.enable = true;
  };

  nixpkgs.config = {
    allowUnfree = true;
    allowBroken = false;
  };

  time.timeZone = "Europe/Kiev";
  i18n.defaultLocale = "en_US.UTF-8";

  systemd.sleep.extraConfig = ''
    HibernateMode=shutdown
  '';

  sound.enable = true;

  security.sudo.wheelNeedsPassword = false;

  users.users.ivan = {
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
      noto-fonts
      noto-fonts-cjk
      noto-fonts-extra
    ];
  };

  system.stateVersion = "21.03";
}
