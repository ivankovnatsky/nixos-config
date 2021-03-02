{ ... }:

{
  programs.home-manager.enable = true;

  home.username = "ivan";
  home.homeDirectory = "/home/ivan";

  imports = [
    ./packages.nix
    ./programs.nix
    ./services.nix
    ./xserver.nix

    ./alacritty.nix
    ./gtk.nix
    ./git.nix
    ./i3status.nix
    ./neovim/default.nix
    ./tmux.nix
    ./zsh.nix
  ];

  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [ (import ./overlays/default.nix) ];

  home.file = {
    ".config/ranger/rc.conf" = {
      text = ''
        set show_hidden true
      '';
    };

    ".terraform.d/plugin-cache/.keep" = {
      text = ''
        keep
      '';
    };

    ".terraformrc" = {
      text = ''
        plugin_cache_dir = "$HOME/.terraform.d/plugin-cache"
      '';
    };
  };

  home.stateVersion = "21.03";
}
