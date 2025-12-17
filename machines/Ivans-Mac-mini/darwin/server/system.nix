{
  system = {
    defaults = {
      CustomUserPreferences = {
        # Disable Apple Intelligence
        # FIXME: Storage is not cleaned yet!
        # https://www.reddit.com/r/MacOS/comments/1id8tns/turning_off_apple_intelligence_from_terminal/
        "com.apple.CloudSubscriptionFeatures.optIn" = {
          "device" = false;
          "auto_opt_in" = false;
        };
        "NSGlobalDomain" = {
          # Auto-switch icon style based on appearance mode
          AppleIconAppearanceTheme = "RegularAutomatic";
        };
      };
    };
  };
}
