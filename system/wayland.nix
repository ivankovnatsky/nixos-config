{ pkgs, ... }:

{
  imports = [
    ./greetd.nix
  ];

  nixpkgs.overlays = [
    (
      self: super: {
        firefox = super.firefox-bin.override { forceWayland = true; };
      }
    )
  ];

  security = {
    pam.services.swaylock = { };
  };

  xdg = {
    portal = {
      enable = true;
      gtkUsePortal = true;

      extraPortals = with pkgs; [
        xdg-desktop-portal-wlr
        xdg-desktop-portal-gtk
      ];
    };
  };

  environment = {
    variables = {
      NIXOS_OZONE_WL = "1";
    };
  };
}
