{
  config,
  lib,
  pkgs,
  ...
}:

# Gaming configuration for Steam Deck
# This module provides configuration and documentation for games installation
{
  # Additional gaming packages that might be useful
  environment.systemPackages = with pkgs; [
    # ProtonUp-Qt - Manage Proton-GE and other compatibility tools for Steam
    # Useful for better compatibility with various games
    protonup-qt
  ];

  # Notes for installing Unreal Tournament games on Steam Deck:
  #
  # Steam is already configured via jovian.nix with auto-start enabled.
  #
  # === Unreal Tournament (1999 / GOTY Edition) ===
  #
  # Installation via Steam:
  # 1. In Desktop Mode, open Steam
  # 2. Install "Unreal Tournament: Game of the Year Edition" from your library
  # 3. The game works via Proton (Steam Play) by default
  # 4. For optimal performance, consider using Proton-GE via ProtonUp-Qt
  #
  # Steam Deck specific settings:
  # - The game works well with Steam Deck controls
  # - You may want to enable Steam Input to customize controls
  # - Default settings should provide good performance on Steam Deck
  #
  # For native Linux version:
  # 1. Download the game files from Steam in Desktop Mode
  # 2. Get the latest OldUnreal patch (v469e or newer) from:
  #    https://github.com/OldUnreal/UnrealTournamentPatches
  # 3. The OldUnreal patch includes native Linux binaries and improvements
  # 4. Native version may offer better battery life
  #
  # === Unreal Tournament 2004 ===
  #
  # UT2004 is not officially available on Steam for Linux, but runs well on Steam Deck.
  #
  # Installation methods:
  #
  # Method 1: Via Proton (if you own it on Steam)
  # 1. In Desktop Mode, open Steam
  # 2. Force Steam Play compatibility for UT2004
  # 3. Install and play via Proton
  #
  # Method 2: Native Linux version (better performance)
  # 1. Install UT2004 via Steam or from GOG/retail
  # 2. Download UT2004 Linux patches from community sources
  # 3. Add as Non-Steam game in Desktop Mode
  # 4. Configure Steam Deck controls via Steam Input
  #
  # Method 3: Heroic Games Launcher (if owned on GOG)
  # 1. Install Heroic Games Launcher from Discover (KDE Store)
  # 2. Link your GOG account
  # 3. Install UT2004 through Heroic
  #
  # Steam Deck specific tips:
  # - Both UT99 and UT2004 run well on Steam Deck's hardware
  # - Native versions may provide better battery life than Proton
  # - Use Desktop Mode for initial setup and configuration
  # - Configure controls in Steam's controller settings for best experience
  # - Consider using performance mode (Settings > Performance) for competitive play
  #
  # === Additional Resources ===
  #
  # - OldUnreal Community: https://www.oldunreal.com/
  # - Steam Deck Gaming: https://steamdeckgaming.com/
  # - ProtonDB for compatibility info: https://www.protondb.com/
  # - PCGamingWiki for troubleshooting:
  #   - UT99: https://www.pcgamingwiki.com/wiki/Unreal_Tournament
  #   - UT2004: https://www.pcgamingwiki.com/wiki/Unreal_Tournament_2004
}
