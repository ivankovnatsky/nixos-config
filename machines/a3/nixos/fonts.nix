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
        monospace = [ "Hack Nerd Font" ];
      };
    };
  };
}
