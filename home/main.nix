{ ... }:

{
  programs.home-manager.enable = true;

  home.username = "ivan";
  home.homeDirectory = "/home/ivan";

  imports = [
    ./pkgs/packages.nix
    ./pkgs/programs.nix
    ./pkgs/services.nix

    ./pkgs/alacritty.nix
    ./pkgs/autorandr.nix
    ./pkgs/gtk.nix
    ./pkgs/git.nix
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

    ".config/rofi/config.rasi" = {
      text = ''
        configuration {
          font: "Hack Nerd Font Mono 10";
          location: 0;
          yoffset: 0;
          xoffset: 0;
          theme: "DarkBlue";
          dpi: 192;
        }
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
