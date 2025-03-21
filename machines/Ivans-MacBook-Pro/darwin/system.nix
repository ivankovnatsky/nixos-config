{
  system = {
    defaults = {
      NSGlobalDomain = {
        # Allow tab focus in all controls, space to select.
        AppleKeyboardUIMode = 3;
        # Repeatable space is killing me.
        InitialKeyRepeat = 120;
        KeyRepeat = 120;
      };
      CustomUserPreferences = {
        # TODO:
        # * Tab layout: Compact tabs
        "com.apple.Safari" = {
          "ShowFullURLInSmartSearchField" = true;
          "ShowStandaloneTabBar" = false; # false enables compact tabs
        };
        "NSGlobalDomain" = {
          # My keyboard does not support Globe switch key, or I don't know how
          # to use it, don't want to use karabiner-elements for now.
          "NSUserKeyEquivalents" = { };
        };
      };
    };
  };
}
