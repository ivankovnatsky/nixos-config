{ config, pkgs, ... }:

let
  hostName = config.networking.hostName or "";

  # Disable automatic rearranging of spaces based on most recent use
  mruSpaces = if hostName == "Lusha-Macbook-Ivan-Kovnatskyi" then false else true;
in
{
  system = {
    activationScripts.postActivation.text = ''
      # Skip if settings appearance was run today (user manually set appearance)
      STATE_FILE="$HOME/.local/state/settings/appearance/last-run"
      TODAY=$(date "+%Y-%m-%d")

      if [ -f "$STATE_FILE" ] && [ "$(cat "$STATE_FILE")" = "$TODAY" ]; then
        echo "Skipping appearance setup (settings appearance was run today)" >&2
      else
        ${pkgs.settings}/bin/settings appearance --init 2>&1 || \
          echo "Warning: Could not set appearance (TCC access may be required)" >&2
      fi
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
