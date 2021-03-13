{ config, lib, pkgs, options, ... }:

{
  imports = [ # Include the results of the hardware scan.
    ./hardware-configuration.nix

    ./environment.nix
    ./general.nix
    ./hardware.nix
    ./nix.nix
    ./packages.nix
    ./programs.nix
    ./security.nix
    ./services.nix
    ./xserver.nix

    <home-manager/nixos>
  ];

  home-manager.users.ivan = { ... }: {
    imports = [ ../home/main.nix ];
    home.stateVersion = config.system.stateVersion;
  };

  networking = {
    hostName = "thinkpad";
    networkmanager.enableStrongSwan = true;
  };

  system.stateVersion = "21.03";
}
