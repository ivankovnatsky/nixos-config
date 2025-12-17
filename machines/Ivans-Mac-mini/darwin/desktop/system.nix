{
  system = {
    defaults = {
      NSGlobalDomain = {
        AppleInterfaceStyle = "Dark";
      };

      CustomUserPreferences = {
        "NSGlobalDomain" = {
          # Use Caps Lock to switch input sources
          TISRomanSwitchState = 1;
        };
        "com.apple.HIToolbox" = {
          # Automatically switch to a document's input source
          AppleGlobalTextInputProperties = {
            TextInputGlobalPropertyPerContextInput = 1;
          };
          # Only ABC and Ukrainian layouts
          AppleEnabledInputSources = [
            {
              InputSourceKind = "Keyboard Layout";
              "KeyboardLayout ID" = 252;
              "KeyboardLayout Name" = "ABC";
            }
            {
              InputSourceKind = "Keyboard Layout";
              "KeyboardLayout ID" = -2354;
              "KeyboardLayout Name" = "Ukrainian-PC";
            }
          ];
        };
      };
    };

    activationScripts.postActivation.text = ''
      echo "Setting desktop wallpaper to solid black..." >&2
      osascript -e '
      tell application "System Events"
          tell every desktop
              set picture to "/System/Library/Desktop Pictures/Solid Colors/Black.png"
          end tell
      end tell
      '
    '';
  };
}
