{ config, lib, pkgs, options, ... }:

{
  imports = [
    ./hardware-configuration.nix

    ./general.nix
    ./graphics.nix
    ./greetd.nix
    ./hardware.nix
    ./nix.nix
    ./monitoring.nix
    ./packages.nix
    ./programs.nix
    ./services.nix
  ];

  nixpkgs.overlays = [ (import ./overlays/default.nix) ];

  networking = {
    hostName = "thinkpad";
    networkmanager.enableStrongSwan = true;
  };

  system.stateVersion = "21.03";
}
