{ ... }:

{
  programs.home-manager.enable = true;

  home.username = "ivan";
  home.homeDirectory = "/home/ivan";

  imports = [
    ./packages.nix
    ./programs.nix
    ./services.nix

    ./pkgs/alacritty.nix
    ./pkgs/autorandr.nix
    ./pkgs/gtk.nix
    ./pkgs/git.nix
    ./pkgs/rofi.nix
    ./pkgs/i3.nix
    ./pkgs/i3status.nix
    ./pkgs/neovim/default.nix
    ./pkgs/tmux.nix
    ./pkgs/zsh.nix
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
