{ pkgs, ... }:

{
  imports = [
    ./greetd.nix
  ];

  security = {
    pam.services.swaylock = { };
  };

  xdg = {
    portal = {
      enable = true;

      extraPortals = with pkgs; [
        xdg-desktop-portal-wlr
        xdg-desktop-portal-gtk
      ];
    };
  };
}
