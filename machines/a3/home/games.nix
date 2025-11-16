{ pkgs, ... }:

{
  # Gaming packages
  # Note: ut1999 requires unfree license acceptance in nixpkgs config
  home.packages = with pkgs; [
    ut1999 # Unreal Tournament GOTY (1999) with OldUnreal patch
    lutris # Gaming platform for managing game installations
  ];

  # Unreal Tournament 1999 (GOTY Edition)
  #
  # The ut1999 package includes:
  # - Complete Unreal Tournament GOTY game from archive.org (officially sanctioned)
  # - OldUnreal patch v469e with native Linux binaries
  # - All maps, textures, sounds, and music
  # - Desktop integration and icons
  #
  # To run: Just type `ut1999` in terminal or find it in your application menu
  #
  # For UT2004:
  # - Use Lutris to install UT2004 with native Linux support
  # - Search for "Unreal Tournament 2004" in Lutris
  # - Use the installer that says "Native 64-bit + Steam" if you own it on Steam
  # - Or use GOG/retail installers available in Lutris database
  #
  # Resources:
  # - OldUnreal Community: https://www.oldunreal.com/
  # - Lutris Game Database: https://lutris.net/
}
