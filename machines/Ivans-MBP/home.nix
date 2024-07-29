{ pkgs, ... }:

{
  imports = [
    ../../modules/flags
    ../../modules/secrets

    ../../home/firefox-config.nix
    ../../home/git.nix
    ../../home/lsd.nix
    ../../home/tmux.nix
    ../../home/shell.nix
    ../../home/direnv.nix
    ../../home/scripts.nix

    ../../home/nixvim
  ];
  flags = {
    purpose = "work";
    editor = "nvim";
    darkMode = false;
  };
  home.packages = with pkgs; [
    # FIXME: move this to default darwin config
    dust
    fswatch
    rectangle
    # To use PC mouse with natural scrolling
    nixpkgs-master.mos
    stats

    magic-wormhole

    ghorg

    docker-client
    docker-compose
    nodejs
    php83Packages.composer

    aws-sso-cli
    aws-sso-creds
  ];

  home.username = "ivan";
  home.stateVersion = "24.05";
  programs.home-manager.enable = true;
}
