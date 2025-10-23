{
  config,
  pkgs,
  username,
  ...
}:

let
  homePath = "${config.users.users.${username}.home}";

in
{
  local = {
    dock = {
      enable = true;
      inherit username;
      # TODO: can dock be stretched 100% horizontally?
      entries = [
        # Default macOS apps
        { path = "/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app/"; }
        { path = "/System/Applications/Calendar.app/"; }
        { path = "/System/Applications/System Settings.app/"; }

        {
          type = "spacer";
          section = "apps";
        }

        # Additional macOS apps
        { path = "/System/Applications/Utilities/Terminal.app/"; }
        { path = "/System/Applications/Utilities/Activity Monitor.app/"; }

        {
          type = "spacer";
          section = "apps";
        }

        # Installed using Kandji
        { path = "/Applications/Google Chrome.app/"; }
        { path = "/Applications/Slack.app/"; }
        { path = "/Applications/zoom.us.app/"; }

        {
          type = "spacer";
          section = "apps";
        }

        # Installed using homebrew
        { path = "/Applications/kitty.app/"; }
        { path = "/Applications/Ghostty.app/"; }
        { path = "/Applications/Firefox Developer Edition.app/"; }
        { path = "/Applications/Chromium.app/"; }
        { path = "/Applications/Comet.app/"; }
        { path = "/Applications/Vivaldi.app/"; }
        { path = "/Applications/DBeaver.app/"; }
        { path = "/Applications/Visual Studio Code.app/"; }
        { path = "/Applications/Cursor.app/"; }
        { path = "/Applications/Windsurf.app/"; }

        {
          path = "${config.users.users.${username}.home}/Downloads/";
          section = "others";
        }
      ];
    };
  };
}
