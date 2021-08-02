{ pkgs, ... }:

{
  fonts = {
    fonts = with pkgs; [
      (nerdfonts.override { fonts = [ "Hack" ]; })
      noto-fonts
      noto-fonts-cjk
      noto-fonts-extra
      noto-fonts-emoji
    ];
  };
}
