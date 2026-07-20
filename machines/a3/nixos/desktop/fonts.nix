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
        # Plasma provides Noto Serif and Noto Sans defaults.
        monospace = [ "Hack Nerd Font" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };
}
