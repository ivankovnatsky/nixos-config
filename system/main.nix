{ config, lib, pkgs, options, ... }:

{
  imports = [ # Include the results of the hardware scan.
    ./hardware-configuration.nix

    <home-manager/nixos>

    ./environment.nix
    ./hardware.nix
    ./general.nix
    ./packages.nix
    ./programs.nix
    ./security.nix
    ./services.nix
    ./xserver.nix
  ];

  home-manager.users.ivan = { ... }: {
    imports = [ ../home/main.nix ];
    home.stateVersion = config.system.stateVersion;
  };

  networking = {
    hostName = "thinkpad";
    networkmanager.enableStrongSwan = true;
  };

  nixpkgs.config.allowUnfree = true;

  nix = {
    autoOptimiseStore = true;
    gc.automatic = true;
    optimise.automatic = true;
  };

  system.stateVersion = "21.03";
}
