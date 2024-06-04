{ config, pkgs, ... }:

{
  imports = [
    ../../home/git.nix
    # ../../home/aichat.nix

    ../../modules/flags
    # ../../modules/secrets
  ];
  # flags = {
  #   purpose = "home";
  #   editor = "nvim";
  #   darkMode = false;
  # };
  home.packages = with pkgs; [
    dust
    fswatch

    ollama
    rectangle

    # To use PC mouse with natural scrolling
    nixpkgs-master.mos
    stats
  ];

  home.username = "ivan";
  home.stateVersion = "23.11";
  programs.home-manager.enable = true;
}
