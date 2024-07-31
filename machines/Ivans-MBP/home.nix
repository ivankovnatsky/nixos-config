{ pkgs, ... }:

{
  imports = [
    ../../modules/flags
    ../../modules/secrets

    ../../home/firefox-config.nix
    ../../home/git.nix
    ../../home/lsd.nix
    ../../home/mpv.nix
    ../../home/tmux.nix
    ../../home/shell.nix
    ../../home/direnv.nix
    ../../home/scripts.nix
    ../../home/k9s.nix

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

    home-manager

    magic-wormhole

    ghorg

    docker-client
    docker-compose
    nodejs
    php83Packages.composer

    awscli2
    aws-sso-cli
    aws-sso-creds

    kubectx
    eks-node-viewer

    go-jsonnet
    jsonnet-bundler
    mimir
    pre-commit
    cmake
  ];
  programs.nixvim = {
    plugins = {
      lsp = {
        servers = {
          terraformls.enable = true;
          eslint.enable = true;
          tsserver.enable = false;
        };
      };
    };
  };
  home.username = "ivan";
  home.stateVersion = "24.05";
  programs.home-manager.enable = true;
}
