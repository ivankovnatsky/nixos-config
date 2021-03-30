{ config, lib, pkgs, options, ... }:

{
  imports = [
    ./hardware-configuration.nix

    ./general.nix
    ./hardware.nix
    ./nix.nix
    ./packages.nix
    ./programs.nix
    ./services.nix

    ./xserver.nix
    ./i3.nix

    <home-manager/nixos>
  ];

  home-manager.useGlobalPkgs = true;
  home-manager.users.ivan = { ... }: {
    imports = [
      ../home/general.nix

      ../home/neovim/default.nix
      ../home/xserver.nix

      ../home/programs.nix

      ../home/alacritty.nix
      ../home/git.nix
      ../home/gtk.nix
      ../home/i3status.nix
      ../home/tmux.nix
      ../home/zsh.nix

      ../home/autorandr.nix
      ../home/dunst.nix
      ../home/i3.nix
      ../home/rofi.nix
    ];

    home.stateVersion = config.system.stateVersion;
  };

  nixpkgs.overlays = [ (import ./overlays/default.nix) ];

  networking = {
    hostName = "thinkpad";
    networkmanager.enableStrongSwan = true;
  };

  system.stateVersion = "21.03";
}
