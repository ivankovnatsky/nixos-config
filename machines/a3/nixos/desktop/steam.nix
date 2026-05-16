{
  pkgs,
  ...
}:

# TODO: Steam Remote Play with powered off Monitor
{
  # Enable Steam
  programs.steam = {
    enable = true;
    # Make the breeze cursor theme visible inside the Steam Runtime
    # (pressure-vessel) container so libXcursor doesn't fall back to the 24px
    # default. https://github.com/NixOS/nixpkgs/issues/437281
    extraPackages = with pkgs; [
      kdePackages.breeze
    ];
  };
}
