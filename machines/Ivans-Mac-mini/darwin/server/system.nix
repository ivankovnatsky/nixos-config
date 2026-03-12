{ pkgs, ... }:

{
  time.timeZone = "Europe/Kyiv";

  system = {
    activationScripts.postActivation.text = ''
      ${pkgs.settings}/bin/settings location --init
    '';

    defaults = {
      CustomUserPreferences = {
        # Disable Apple Intelligence
        # FIXME: Storage is not cleaned yet!
        # https://www.reddit.com/r/MacOS/comments/1id8tns/turning_off_apple_intelligence_from_terminal/
        "com.apple.CloudSubscriptionFeatures.optIn" = {
          "device" = false;
          "auto_opt_in" = false;
        };
      };
    };
  };
}
