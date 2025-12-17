{ config, ... }:

let
  hostName = config.networking.hostName or "";

  # Disable automatic rearranging of spaces based on most recent use
  mruSpaces = if hostName == "Lusha-Macbook-Ivan-Kovnatskyi" then false else true;
in
{
  system = {
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

    defaults = {
      controlcenter = {
        Bluetooth = false;
      };
      dock = {
        # https://github.com/nix-darwin/nix-darwin/blob/6cb36e8327421c61e5a3bbd08ed63491b616364a/modules/system/defaults/dock.nix#L114
        mru-spaces = mruSpaces;
        tilesize = 64;
        # Auto-hide dock with a huge delay (effectively hidden unless you wait)
        autohide = false;
        autohide-delay = 1000.0;
      };
      finder = {
        FXRemoveOldTrashItems = true;
      };
      NSGlobalDomain = {
        # Allow tab focus in all controls, space to select.
        AppleKeyboardUIMode = 3;
        # Repeatable space is killing me.
        InitialKeyRepeat = 120;
        KeyRepeat = 120;
        AppleInterfaceStyle = "Dark";
      };
      # https://github.com/nix-darwin/nix-darwin/blob/master/modules/system/defaults/WindowManager.nix#L6
      WindowManager = {
        EnableTilingByEdgeDrag = true;
        EnableTopTilingByEdgeDrag = true;
        EnableTilingOptionAccelerator = true;
        EnableTiledWindowMargins = true;
      };
      CustomUserPreferences = {
        "NSGlobalDomain" = {
          # Auto-switch icon style based on appearance mode
          AppleIconAppearanceTheme = "RegularAutomatic";
          # My keyboard does not support Globe switch key, or I don't know how
          # to use it, don't want to use karabiner-elements for now.
          "NSUserKeyEquivalents" = {
            "Move focus to active or next window" = "~`";
          };
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
  };
}
