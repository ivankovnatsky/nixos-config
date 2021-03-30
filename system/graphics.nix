{ lib, pkgs, ... }:

{
  nixpkgs.overlays = [
    (self: super: {
      xdg-desktop-portal-wlr = super.xdg-desktop-portal-wlr.overrideAttrs
        (oldAttrs: rec {
          nativeBuildInputs = oldAttrs.nativeBuildInputs
            ++ [ pkgs.makeWrapper ];
          postInstall = ''
            wrapProgram $out/libexec/xdg-desktop-portal-wlr --prefix PATH ":" ${
              lib.makeBinPath [ pkgs.slurp ]
            }
          '';
        });
    })
  ];

  xdg = {
    icons.enable = true;

    portal = {
      enable = true;
      gtkUsePortal = true;

      extraPortals = with pkgs; [
        xdg-desktop-portal-wlr
        xdg-desktop-portal-gtk
      ];
    };
  };
}
