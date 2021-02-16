{ ... }:

{
  programs.home-manager.enable = true;

  home.username = "ivan";
  home.homeDirectory = "/home/ivan";

  imports = [
    ./packages.nix
    ./programs.nix
    ./services.nix

    ./alacritty.nix
    ./autorandr.nix
    ./gtk.nix
    ./git.nix
    ./rofi.nix
    ./i3.nix
    ./i3status.nix
    ./neovim/default.nix
    ./tmux.nix
    ./zsh.nix
  ];

  nixpkgs.config.allowUnfree = true;

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
        plugin_cache_dir   = "$HOME/.terraform.d/plugin-cache"
      '';
    };

    # xterm is installed anyway:
    # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/x11/xserver.nix#L651
    ".Xresources" = {
      text = ''
        XTerm*faceName:        xft:Hack Nerd Font Mono:size=10
        XTerm*utf8:            2
        XTerm*background:      #000000
        XTerm*foreground:      #FFFFFF
        XTerm*metaSendsEscape: true
      '';
    };
  };

  home.stateVersion = "21.03";
}
