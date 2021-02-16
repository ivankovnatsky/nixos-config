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

  nixpkgs.config = { allowUnfree = true; };

  # nixpkgs.overlays = [ (import ./overlays/terraform.nix) ];

  home.file = {
    ".config/ranger/rc.conf" = {
      text = ''
        set show_hidden true
      '';
    };

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
