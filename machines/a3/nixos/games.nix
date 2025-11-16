{
  config,
  lib,
  pkgs,
  ...
}:

# Gaming configuration for a3 machine
# This module provides configuration and documentation for games installation
{
  # Additional gaming packages that might be useful
  environment.systemPackages = with pkgs; [
    # Lutris - Gaming platform for managing game installations
    # Useful for installing games like UT2004 with native Linux versions
    lutris

    # ProtonUp-Qt - Manage Proton-GE and other compatibility tools for Steam
    protonup-qt
  ];

  # Notes for installing Unreal Tournament games:
  #
  # === Unreal Tournament (1999 / GOTY Edition) ===
  #
  # Installation via Steam:
  # 1. Install "Unreal Tournament: Game of the Year Edition" from Steam
  # 2. The game works via Proton (Steam Play) by default
  #
  # For better performance with native Linux version:
  # 1. Download the game files from Steam
  # 2. Get the latest OldUnreal patch (v469e or newer) from:
  #    https://github.com/OldUnreal/UnrealTournamentPatches
  # 3. The OldUnreal patch includes native Linux binaries and improvements
  #
  # === Unreal Tournament 2004 ===
  #
  # UT2004 is not officially available on Steam for Linux, but has native Linux support.
  #
  # Installation methods:
  #
  # Method 1: Using Lutris (Recommended)
  # 1. Open Lutris
  # 2. Search for "Unreal Tournament 2004"
  # 3. Use the installer that says "Native 64-bit + Steam"
  # 4. Lutris will handle downloading from Steam and setting up native binaries
  #
  # Method 2: Manual installation
  # 1. Install UT2004 on Windows via Steam or use Wine
  # 2. Copy the game files to Linux
  # 3. Download UT2004 Linux patches from:
  #    https://github.com/ut-linux/ut2004
  # 4. Extract and run the native Linux binaries
  #
  # Method 3: From retail CD/DVD
  # 1. Install from physical media or GOG version
  # 2. Apply the latest Linux patches
  #
  # === Additional Resources ===
  #
  # - OldUnreal Community: https://www.oldunreal.com/
  # - Lutris Game Database: https://lutris.net/
  # - PCGamingWiki for troubleshooting:
  #   - UT99: https://www.pcgamingwiki.com/wiki/Unreal_Tournament
  #   - UT2004: https://www.pcgamingwiki.com/wiki/Unreal_Tournament_2004
}
