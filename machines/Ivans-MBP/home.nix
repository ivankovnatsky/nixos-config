{ config, pkgs, ... }:

{
  imports = [
    ../../home/git.nix

    ../../modules/flags
  ];
  flags = {
    purpose = "home";
    editor = "vim";
    darkMode = false;
  };
  home.packages = with pkgs; [
    dust
    fswatch

    rectangle

    # To use PC mouse with natural scrolling
    nixpkgs-master.mos
    stats
  ];

  home.username = "ivan";
  home.stateVersion = "24.05";
  programs.home-manager.enable = true;
}
