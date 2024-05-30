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
    ollama
    rectangle
  ];

  home.username = "ivan";
  home.stateVersion = "23.11";
  programs.home-manager.enable = true;
}
