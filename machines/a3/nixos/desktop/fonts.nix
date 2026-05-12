{ pkgs, ... }:

{
  fonts = {
    # Enable font packages
    packages = with pkgs; [
      nerd-fonts.hack
    ];

    # Enable default fonts
    enableDefaultPackages = true;

    # Font configuration
    fontconfig = {
      defaultFonts = {
        serif = [ "DejaVu Serif" ];
        sansSerif = [ "DejaVu Sans" ];
        monospace = [ "Hack Nerd Font" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };
}
