{
  system = {
    defaults = {
      CustomUserPreferences = {
        "com.apple.HIToolbox" = {
          # Use Caps Lock to switch input sources
          TISRomanSwitchState = 1;
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
  };
}
