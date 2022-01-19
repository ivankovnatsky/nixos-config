{
  imports = [
    ./greetd.nix
    ./swaylock.nix
    ./xdg-portal.nix
  ];

  nixpkgs.overlays = [
    (
      self: super: {
        firefox = super.firefox.override { forceWayland = true; };
      }
    )
  ];
}
