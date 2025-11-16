{ pkgs, ... }:

{
  home.packages = with pkgs; [
    ut1999 # Unreal Tournament GOTY (1999) with OldUnreal patch
    lutris # Gaming platform for managing game installations
  ];
}
