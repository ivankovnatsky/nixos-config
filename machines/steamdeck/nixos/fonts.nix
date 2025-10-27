{ pkgs, ... }:

{
  fonts = {
    packages = with pkgs; [
      nerd-fonts.hack
    ];

    enableDefaultPackages = true;

    fontconfig = {
      defaultFonts = {
        monospace = [ "Hack Nerd Font" ];
      };
    };
  };
}
