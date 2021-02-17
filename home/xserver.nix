{ pkgs, ... }:

{
  imports = [ ./autorandr.nix ./rofi.nix ./i3.nix ];

  home.file = {
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

  home.packages = with pkgs; [ arandr maim xclip xorg.xev ];
}
