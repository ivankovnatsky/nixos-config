{ ... }:

{
  programs.home-manager.enable = true;

  home.username = "ivan";
  home.homeDirectory = "/home/ivan";

  imports = [
    ./modules/packages.nix
    ./modules/programs.nix
    ./modules/services.nix

    ./modules/alacritty.nix
    ./modules/autorandr.nix
    ./modules/gtk.nix
    ./modules/git.nix
    ./modules/i3.nix
    ./modules/i3status.nix
    ./modules/neovim.nix
    ./modules/tmux.nix
    ./modules/zsh.nix
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
          font: "Hack Nerd Font Mono 20";
          location: 0;
          yoffset: 0;
          xoffset: 0;
          theme: "DarkBlue";
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
