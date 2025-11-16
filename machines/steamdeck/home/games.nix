{ pkgs, ... }:

{
  # Gaming packages
  # Note: ut1999 requires unfree license acceptance in nixpkgs config
  home.packages = with pkgs; [
    ut1999 # Unreal Tournament GOTY (1999) with OldUnreal patch
  ];
}
